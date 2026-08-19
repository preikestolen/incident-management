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
            'expand',
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
};
