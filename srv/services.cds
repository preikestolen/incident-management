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
    entity Incidents          as projection on my.Incidents;

    @readonly
    entity Customers          as projection on my.Customers;

    // ✅ Add statistics — read only, no draft needed
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
//annotate ProcessorService.Incidents with @odata.draft.bypass;

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
