const cds = require('@sap/cds')

class ProcessorService extends cds.ApplicationService {

  /** Registering custom event handlers */
  init() {
    this.before("UPDATE", "Incidents", (req) => this.onUpdate(req));
    this.before("CREATE", "Incidents", (req) => this.changeUrgencyDueToSubject(req.data));
    this.before("UPDATE", "Incidents", (req) => this.changeUrgencyDueToSubject(req.data));
    this.on("escalateIncident", (req) => this.onEscalate(req));
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
    if (closed) req.reject`Can't modify a closed incident!`
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
}

module.exports = { ProcessorService }