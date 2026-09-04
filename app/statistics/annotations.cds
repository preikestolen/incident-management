using ProcessorService as service from '../../srv/services';

annotate service.IncidentsByStatus with @(
    Aggregation.ApplySupported             : {
        Transformations       : [
            'aggregate',
            'topcount',
            'bottomcount',
            'identity',
            'concat',
            'groupby',
            'filter',
            'search'
        ],
        Rollup                : #None,
        PropertyRestrictions  : true,
        GroupableProperties   : [
            status_code,
            status_name,
            criticality
        ],
        AggregatableProperties: [{Property: count}]
    },
    Analytics.AggregatedProperty #count_sum: {
        $Type               : 'Analytics.AggregatedPropertyType',
        Name                : 'count_sum',
        AggregatableProperty: count,
        AggregationMethod   : 'sum',
        ![@Common.Label]    : 'Count'
    },
    UI.SelectionFields                     : [status_code],
    UI.Chart                               : {
        $Type          : 'UI.ChartDefinitionType',
        Title          : 'Incidents by Status',
        ChartType      : #Column,
        Dimensions     : [status_name],
        DynamicMeasures: ['@Analytics.AggregatedProperty#count_sum']
    },
    UI.PresentationVariant                 : {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: [
            '@UI.Chart',
            '@UI.LineItem'
        ]
    },
    UI.LineItem                            : [
        {
            $Type: 'UI.DataField',
            Value: status_name,
            Label: 'Status'
        },
        {
            $Type: 'UI.DataField',
            Value: count,
            Label: 'Count'
        },
        {
            $Type: 'UI.DataField',
            Value: criticality,
            Label: 'Criticality'
        }
    ]
);

annotate service.IncidentsByStatus with {
    status_name @Common.Label: 'Status';
    status_code @(
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
};
