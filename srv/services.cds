using {sap.capire.incidents as my} from '../db/schema';

/**
 * Service used by support personell, i.e. the incidents' 'processors'.
 */
service ProcessorService {
    @Capabilities: {
        InsertRestrictions.Insertable: true,
        UpdateRestrictions.Updatable : true,
        DeleteRestrictions.Deletable : true
    }
    @cds.redirection.target
    entity Incidents          as projection on my.Incidents
        actions {
            action escalateIncident(assigneeName: String) returns Incidents;
            action closeIncident()                        returns Incidents;
            action assignToCustomer(customerId: String)   returns Incidents;
            action reopenIncident()                       returns Incidents;
            action sendNotification(toEmail: String @(
                title: 'Recipient Email',
                UI.ParameterDefaultValue: in.customer.email
            ),
                                    subject: String @title: 'Subject',
                                    message: String @title: 'Message',
                                    cc: String @title: 'CC'
            )                                             returns Incidents;
        };

    //@readonly
    @cds.redirection.target
    entity Conversations      as projection on my.Conversations;

    @readonly
    entity ConversationFeed   as
        select from my.Conversations as c {
            key c.ID,
                c.timestamp,
                c.author,
                c.message,
                c.up_.title              as incident_title,
                c.up_.status.code        as status_code,
                c.up_.status.descr       as status_descr,
                c.up_.status.criticality as criticality,
                c.up_.urgency.code       as urgency_code,
                c.up_.urgency.descr      as urgency_descr,
                c.up_.ID                 as incident_ID,
                case
                    c.up_.urgency.code
                    when 'H'
                         then 1
                    when 'M'
                         then 2
                    when 'L'
                         then 3
                    else 0
                end                      as urgency_criticality : Integer
        };

    @readonly
    entity Customers          as projection on my.Customers;

    @readonly
    entity IncidentsByStatus  as
        select from my.Incidents {
            key status.code        as status_code,
                status.descr       as status_name,
                status.criticality as criticality,
                count( * )         as count : Integer
        }
        group by
            status.code,
            status.descr,
            status.criticality;

    @readonly
    entity IncidentsByUrgency as
        select from my.Incidents {
            key urgency.code  as urgency_code,
                urgency.descr as urgency_name,
                count( * )    as count : Integer
        }
        group by
            urgency.code,
            urgency.descr;
}

annotate ProcessorService.Incidents with @odata.draft.enabled;

/**
 * Service used by administrators to manage customers and incidents.
 */
service AdminService {
    entity Customers                   as projection on my.Customers;
    entity Incidents @odata.insertable as projection on my.Incidents;
}

annotate ProcessorService.Incidents with @odata.insertable;

annotate ProcessorService with @(requires: 'support');
annotate AdminService with @(requires: 'admin');

service CatalogService {
    function sendMail() returns String;
}
