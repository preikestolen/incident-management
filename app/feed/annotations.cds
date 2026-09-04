using ProcessorService as service from '../../srv/services';

annotate service.ConversationFeed with @(
    UI.HeaderInfo         : {
        TypeName      : 'Activity',
        TypeNamePlural: 'Activities',
        Title         : {
            $Type: 'UI.DataField',
            Value: author
        },
        Description   : {
            $Type: 'UI.DataField',
            Value: incident_title
        }
    },
    UI.SelectionFields    : [
        author,
        status_code,
        urgency_code,
        timestamp
    ],
    UI.PresentationVariant: {
        $Type         : 'UI.PresentationVariantType',
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : timestamp,
            Descending: true
        }],
        Visualizations: ['@UI.LineItem']
    },
    UI.LineItem           : {
        $value            : [
            {
                $Type: 'UI.DataField',
                Value: timestamp,
                Label: 'Time'
            },
            {
                $Type: 'UI.DataField',
                Value: author,
                Label: 'Written By'
            },
            {
                $Type: 'UI.DataField',
                Value: incident_title,
                Label: 'Incident'
            },
            {
                $Type: 'UI.DataField',
                Value: message,
                Label: 'Message'
            },
            {
                $Type      : 'UI.DataField',
                Value      : status_descr,
                Label      : 'Status',
                Criticality: criticality
            },
            {
                $Type      : 'UI.DataField',
                Value      : urgency_descr,
                Label      : 'Urgency',
                Criticality: urgency_criticality
            }
        ],
        ![@UI.Criticality]: urgency_criticality
    }
);

annotate service.ConversationFeed with {
    timestamp      @Common.Label: 'Time';
    author         @Common.Label: 'Written By';
    incident_title @Common.Label: 'Incident';
    message        @Common.Label: 'Message';
    status_descr   @Common.Label: 'Status';
    urgency_descr  @Common.Label: 'Urgency';
    status_code    @(
        Common.Label                   : 'Status',
        Common.ValueListWithFixedValues: true,
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Status',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: status_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'descr'
                }
            ]
        }
    );
    urgency_code   @(
        Common.Label                   : 'Urgency',
        Common.ValueListWithFixedValues: true,
        Common.ValueList               : {
            $Type         : 'Common.ValueListType',
            CollectionPath: 'Urgency',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: urgency_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'descr'
                }
            ]
        }
    );
};
