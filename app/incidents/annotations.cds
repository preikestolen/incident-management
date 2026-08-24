using ProcessorService as service from '../../srv/services';
using from '../../db/schema';

annotate service.Incidents with @(
    UI.FieldGroup #GeneratedGroup    : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: title,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>Customerid}',
                Value: customer_ID,
            },
        ],
    },
    UI.Facets                        : [
        {
            $Type : 'UI.CollectionFacet',
            Label : 'Overview',
            ID    : 'Overview',
            Facets: [
                {
                    $Type : 'UI.ReferenceFacet',
                    Label : 'General Information',
                    ID    : 'GeneralInformation',
                    Target: '@UI.FieldGroup#GeneralInformation',
                },
                {
                    $Type : 'UI.ReferenceFacet',
                    Label : '{i18n>Details}',
                    ID    : 'i18nDetails',
                    Target: '@UI.FieldGroup#i18nDetails',
                },
            ],
        },
        {
            $Type : 'UI.CollectionFacet',
            Label : '{i18n>Conversation}',
            ID    : 'i18nOverview',
            Facets: [{
                $Type : 'UI.ReferenceFacet',
                Label : '{i18n>Conversation}',
                ID    : 'Conversation',
                Target: 'conversation/@UI.LineItem#Conversation',
            }, ],
        },
    ],
    UI.LineItem                      : [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'ProcessorService.escalateIncident',
            Label : 'Escalate',
            Inline: false
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'ProcessorService.closeIncident',
            Label : 'Close Incident',
            Inline: false
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'ProcessorService.assignToCustomer',
            Label : 'Assign to Customer',
            Inline: false
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'ProcessorService.reopenIncident',
            Label : 'Reopen',
            Inline: false
        },
        {
            $Type: 'UI.DataField',
            Value: title,
            Label: '{i18n>Title}',
        },
        {
            $Type: 'UI.DataField',
            Value: customer_ID,
        },
        {
            $Type: 'UI.DataField',
            Value: urgency_code,
        },
        {
            $Type      : 'UI.DataField',
            Value      : status_code,
            Criticality: status.criticality,
        },
    ],
    UI.SelectionFields               : [
        status_code,
        customer_ID,
        title,
        urgency_code,
    ],
    UI.HeaderInfo                    : {
        Title         : {
            $Type: 'UI.DataField',
            Value: title,
        },
        TypeName      : '',
        TypeNamePlural: '',
        Description   : {
            $Type: 'UI.DataField',
            Value: customer.name,
        },
        TypeImageUrl  : 'sap-icon://alert',
    },
    UI.FieldGroup #i18nDetails       : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type      : 'UI.DataField',
                Value      : status_code,
                Criticality: status.criticality,
            },
            {
                $Type: 'UI.DataField',
                Value: urgency_code,
            },
        ],
    },
    UI.FieldGroup #Details           : {
        $Type: 'UI.FieldGroupType',
        Data : [],
    },
    UI.FieldGroup #Details1          : {
        $Type: 'UI.FieldGroupType',
        Data : [],
    },
    UI.Identification                : [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'ProcessorService.escalateIncident',
            Label : 'Escalate'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'ProcessorService.closeIncident',
            Label : 'Close Incident'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'ProcessorService.assignToCustomer',
            Label : 'Assign to Customer'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'ProcessorService.reopenIncident',
            Label : 'Reopen'
        }
    ],
    UI.FieldGroup #GeneralInformation: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: title,
            },
            {
                $Type: 'UI.DataField',
                Value: customer_ID,
            },
        ],
    },
);

annotate service.Incidents with {
    customer @(
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Customers',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: customer_ID,
                    ValueListProperty: 'ID',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'name',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'email',
                },
            ],
        },
        Common.Label                   : '{i18n>Customerid}',
        Common.Text                    : customer.name,
        Common.Text.@UI.TextArrangement: #TextOnly,
        Common.ValueListWithFixedValues: true,
    )
};

annotate service.Incidents with {
    status @(
        Common.Label                   : '{i18n>Statuscode}',
        Common.ValueListWithFixedValues: true,
        Common.Text                    : status.descr,
    )
};

annotate service.Incidents with {
    urgency @(
        Common.Label                   : '{i18n>Urgency}',
        Common.ValueListWithFixedValues: true,
        Common.Text                    : urgency.descr,
    )
};

annotate service.Urgency with {
    code @Common.Text: descr
};

annotate service.Status with {
    code @Common.Text: descr
};

annotate service.Incidents.conversation with @(UI.LineItem #Conversation: [
    {
        $Type: 'UI.DataField',
        Value: author,
    },
    {
        $Type: 'UI.DataField',
        Value: message,
        Label: 'message',
    },
    {
        $Type: 'UI.DataField',
        Value: timestamp,
    },
]);

annotate ProcessorService.Incidents with actions {
    escalateIncident @(
        Core.OperationAvailable        : in.IsActiveEntity,
        Common.SideEffects             : {
            TargetProperties: [
                'in/status_code',
                'in/urgency_code'
            ],
            TargetEntities  : [conversation]
        },
        cds.odata.bindingparameter.name: 'in'
    );
    closeIncident    @(
        Core.OperationAvailable        : in.IsActiveEntity,
        Common.SideEffects             : {
            TargetProperties: ['in/status_code'],
            TargetEntities  : [conversation]
        },
        cds.odata.bindingparameter.name: 'in'
    );
};

annotate ProcessorService.Incidents with actions {
    assignToCustomer @(
        Core.OperationAvailable        : in.IsActiveEntity,
        Common.SideEffects             : {
            TargetProperties: [
                'in/customer_ID',
                'in/status_code'
            ],
            TargetEntities  : [conversation]
        },
        cds.odata.bindingparameter.name: 'in'
    );
};

annotate ProcessorService.Incidents actions {
    escalateIncident(assigneeName @title: 'Assignee Name' );
};

annotate ProcessorService.Incidents actions {
    assignToCustomer(customerId @(
        title           : 'Customer',
        Common.ValueList: {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Customers',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: customerId,
                    ValueListProperty: 'ID',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'name',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'email',
                },
            ]
        }
    )
    );
};

annotate ProcessorService.Incidents with actions {
    reopenIncident @(
        Core.OperationAvailable        : in.IsActiveEntity,
        Common.SideEffects             : {
            TargetProperties: ['in/status_code'],
            TargetEntities  : [conversation]
        },
        cds.odata.bindingparameter.name: 'in'
    );
};
