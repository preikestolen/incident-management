const cds = require('@sap/cds')
const SapCfMailer = require('sap-cf-mailer').default

class ProcessorService extends cds.ApplicationService {
  init() {
    this.before('UPDATE', 'Incidents', req => this.onUpdate(req))
    this.before('CREATE', 'Incidents', req =>
      this.changeUrgencyDueToSubject(req.data)
    )
    this.before('UPDATE', 'Incidents', req =>
      this.changeUrgencyDueToSubject(req.data)
    )

    this.on('escalateIncident', req => this.onEscalate(req))
    this.on('closeIncident', req => this.onClose(req))
    this.on('assignToCustomer', req => this.onAssignToCustomer(req))
    this.on('reopenIncident', req => this.onReopen(req))
    this.on('sendNotification', req => this.onSendNotification(req))

    return super.init()
  }

  changeUrgencyDueToSubject(data) {
    const urgent = data.title?.match(/urgent/i)
    if (urgent) data.urgency_code = 'H'
  }

  async onUpdate(req) {
    const incidentId = req.data.ID || req.params?.[0]?.ID
    if (!incidentId) return

    const closed = await SELECT.one
      .from('sap.capire.incidents.Incidents')
      .columns('ID')
      .where({ ID: incidentId, status_code: 'C' })

    if (closed) {
      return req.reject(409, "Can't modify a closed incident!")
    }
  }

  async onEscalate(req) {
    const { assigneeName } = req.data
    const incidentId = req.params[0].ID

    const incident = await SELECT.one
      .from('sap.capire.incidents.Incidents')
      .columns('ID', 'title', 'customer_ID')
      .where({ ID: incidentId })

    if (!incident) {
      return req.reject(404, `Incident ${incidentId} not found`)
    }

    const customer = await SELECT.one
      .from('sap.capire.incidents.Customers')
      .columns('ID', 'name', 'email')
      .where({ ID: incident.customer_ID })

    if (!customer) {
      return req.reject(404, 'Incident customer not found')
    }

    if (!customer.email) {
      return req.reject(400, 'Incident customer has no email address')
    }

    const message =
      `This issue has been escalated and assigned to ${assigneeName}.`

    await UPDATE('sap.capire.incidents.Incidents')
      .set({
        urgency_code: 'H',
        status_code: 'A'
      })
      .where({ ID: incidentId })

    await INSERT.into('sap.capire.incidents.Conversations').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: new Date().toISOString(),
      author: req.user?.id || 'System',
      message
    })

    try {
      const mailer = new SapCfMailer('GmailSMTP')

      await mailer.sendMail({
        to: customer.email,
        subject: `Incident Escalated: ${incident.title}`,
        text: [
          `Incident: ${incident.title}`,
          `Assignee: ${assigneeName}`,
          'Status: Assigned',
          'Urgency: High',
          `Message: ${message}`
        ].join('\n'),
        html: `
            <h2>Incident Escalated</h2>
            <p><strong>Incident:</strong> ${incident.title}</p>
            <p><strong>Assignee:</strong> ${assigneeName}</p>
            <p><strong>Status:</strong> Assigned</p>
            <p><strong>Urgency:</strong> High</p>
            <p>${message}</p>
          `
      })
    } catch (error) {
      console.error('Escalation email failed:', error)
      return req.reject(
        502,
        'Incident escalated, but notification email could not be sent'
      )
    }

    return SELECT.one
      .from('sap.capire.incidents.Incidents')
      .where({ ID: incidentId })
  }

  async onClose(req) {
    const incidentId = req.params[0].ID

    await UPDATE('sap.capire.incidents.Incidents')
      .set({ status_code: 'C' })
      .where({ ID: incidentId })

    await INSERT.into('sap.capire.incidents.Conversations').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: new Date().toISOString(),
      author: req.user?.id || 'System',
      message: 'Incident has been closed.'
    })

    return SELECT.one
      .from('sap.capire.incidents.Incidents')
      .where({ ID: incidentId })
  }

  async onAssignToCustomer(req) {
    const { customerId } = req.data
    const incidentId = req.params[0].ID

    const customer = await SELECT.one
      .from('sap.capire.incidents.Customers')
      .where({ ID: customerId })

    if (!customer) {
      return req.reject(404, `Customer ${customerId} not found`)
    }

    await UPDATE('sap.capire.incidents.Incidents')
      .set({
        customer_ID: customerId,
        status_code: 'A'
      })
      .where({ ID: incidentId })

    await INSERT.into('sap.capire.incidents.Conversations').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: new Date().toISOString(),
      author: req.user?.id || 'System',
      message: `Incident assigned to customer ${customer.name}.`
    })

    return SELECT.one
      .from('sap.capire.incidents.Incidents')
      .where({ ID: incidentId })
  }

  async onReopen(req) {
    const incidentId = req.params[0].ID

    await UPDATE('sap.capire.incidents.Incidents')
      .set({ status_code: 'N' })
      .where({ ID: incidentId })

    await INSERT.into('sap.capire.incidents.Conversations').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: new Date().toISOString(),
      author: req.user?.id || 'System',
      message: 'Incident has been reopened.'
    })

    return SELECT.one
      .from('sap.capire.incidents.Incidents')
      .where({ ID: incidentId })
  }

  async onSendNotification(req) {
    const incidentId = req.params[0].ID
    const { toEmail, subject, message, cc } = req.data

    const incident = await SELECT.one
      .from('sap.capire.incidents.Incidents')
      .columns('ID', 'title', 'customer_ID')
      .where({ ID: incidentId })

    if (!incident) {
      return req.reject(404, `Incident ${incidentId} not found`)
    }

    const customer = await SELECT.one
      .from('sap.capire.incidents.Customers')
      .columns('ID', 'email')
      .where({ ID: incident.customer_ID })

    const recipient = toEmail?.trim() || customer?.email

    if (!recipient) {
      return req.reject(400, 'No recipient email address is available')
    }

    if (!subject?.trim()) {
      return req.reject(400, 'Email subject is required')
    }

    if (!message?.trim()) {
      return req.reject(400, 'Email message is required')
    }

    try {
      const mailer = new SapCfMailer('GmailSMTP')

      await mailer.sendMail({
        to: recipient,
        cc: cc?.trim() || undefined,
        subject: subject.trim(),
        text: message.trim(),
        html: `
            <h2>${subject.trim()}</h2>
            <p>${message.trim().replace(/\n/g, '<br>')}</p>
          `
      })
    } catch (error) {
      console.error('Notification email failed:', error)
      return req.reject(502, 'Notification email could not be sent')
    }

    await INSERT.into('sap.capire.incidents.Conversations').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: new Date().toISOString(),
      author: req.user?.id || 'System',
      message: `Notification sent to ${recipient}.`
    })

    return SELECT.one
      .from('sap.capire.incidents.Incidents')
      .where({ ID: incidentId })
  }
}

class CatalogService extends cds.ApplicationService {
  init() {
    this.on('sendMail', async req => {
      const recipient = process.env.TEST_MAIL_TO

      if (!recipient) {
        return req.reject(
          400,
          'TEST_MAIL_TO environment variable is missing'
        )
      }

      try {
        const mailer = new SapCfMailer('GmailSMTP')

        await mailer.sendMail({
          to: recipient,
          subject: 'Test Mail from SAP CAP',
          text: 'Hello from the local CAP application.',
          html: `
              <h2>Test Mail from SAP CAP</h2>
              <p>Hello from the local CAP application.</p>
              <p>This email was sent using sap-cf-mailer.</p>
            `
        })

        return 'Email sent successfully'
      } catch (error) {
        console.error('Error sending email:', error)
        return req.reject(500, `Error sending email: ${error.message}`)
      }
    })

    return super.init()
  }
}

module.exports = {
  ProcessorService,
  CatalogService
}