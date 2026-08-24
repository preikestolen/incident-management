const cds = require('@sap/cds')

class ProcessorService extends cds.ApplicationService {

  /** Registering custom event handlers */
  init() {
    this.before("UPDATE", "Incidents", (req) => this.onUpdate(req));
    this.before("CREATE", "Incidents", (req) => this.changeUrgencyDueToSubject(req.data));
    this.before("UPDATE", "Incidents", (req) => this.changeUrgencyDueToSubject(req.data));
    this.on("escalateIncident", (req) => this.onEscalate(req));
    this.on("closeIncident", (req) => this.onClose(req));
    this.on("assignToCustomer", (req) => this.onAssignToCustomer(req));
    this.on("reopenIncident", (req) => this.onReopen(req));
    return super.init();
  }

  changeUrgencyDueToSubject(data) {
    let urgent = data.title?.match(/urgent/i)
    if (urgent) data.urgency_code = 'H'
  }

  /** Custom Validation */
  async onUpdate(req) {
    let closed = await SELECT.one(1)
      .from(req.subject)
      .where`status.code = 'C'`
    if (closed) req.reject(409, 'Can\'t modify a closed incident!')
  }

  async onEscalate(req) {
    const { assigneeName } = req.data
    const incidentId = req.params[0].ID

    await UPDATE('sap.capire.incidents.Incidents')
      .set({ urgency_code: 'H', status_code: 'A' })
      .where({ ID: incidentId })

    await INSERT.into('sap.capire.incidents.Incidents_conversation').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: (new Date()).toISOString(),
      author: req.user?.id || 'System',
      message: `This issue has been escalated and assigned to ${assigneeName}.`
    })

    return SELECT.one('sap.capire.incidents.Incidents').where({ ID: incidentId })
  }

  async onClose(req) {
    const incidentId = req.params[0].ID

    await UPDATE('sap.capire.incidents.Incidents')
      .set({ status_code: 'C' })
      .where({ ID: incidentId })

    await INSERT.into('sap.capire.incidents.Incidents_conversation').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: (new Date()).toISOString(),
      author: req.user?.id || 'System',
      message: 'Incident has been closed.'
    })

    return SELECT.one('sap.capire.incidents.Incidents').where({ ID: incidentId })
  }

  async onAssignToCustomer(req) {
    const { customerId } = req.data
    const incidentId = req.params[0].ID

    const customer = await SELECT.one('sap.capire.incidents.Customers')
      .where({ ID: customerId })

    if (!customer) req.reject(404, `Customer ${customerId} not found`)

    await UPDATE('sap.capire.incidents.Incidents')
      .set({ customer_ID: customerId, status_code: 'A' })
      .where({ ID: incidentId })

    await INSERT.into('sap.capire.incidents.Incidents_conversation').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: (new Date()).toISOString(),
      author: req.user?.id || 'System',
      message: `Incident assigned to customer ${customer.name}.`
    })

    return SELECT.one('sap.capire.incidents.Incidents').where({ ID: incidentId })
  }

  async onReopen(req) {
    const incidentId = req.params[0].ID

    await UPDATE('sap.capire.incidents.Incidents')
      .set({ status_code: 'N' })
      .where({ ID: incidentId })

    await INSERT.into('sap.capire.incidents.Incidents_conversation').entries({
      ID: cds.utils.uuid(),
      up__ID: incidentId,
      timestamp: (new Date()).toISOString(),
      author: req.user?.id || 'System',
      message: 'Incident has been reopened.'
    })

    return SELECT.one('sap.capire.incidents.Incidents').where({ ID: incidentId })
  }
}

module.exports = { ProcessorService }