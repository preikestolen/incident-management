using ProcessorService as service from '../../srv/services';

annotate service.IncidentsByUrgency with @(
    Aggregation.ApplySupported                     : {
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
            urgency_code,
            urgency_name
        ],
        AggregatableProperties: [{Property: count}]
    },
    Analytics.AggregatedProperty #urgency_count_sum: {
        $Type               : 'Analytics.AggregatedPropertyType',
        Name                : 'urgency_count_sum',
        AggregatableProperty: count,
        AggregationMethod   : 'sum',
        ![@Common.Label]    : 'Count'
    },
    UI.SelectionFields                             : [urgency_code],
    UI.Chart                                       : {
        $Type          : 'UI.ChartDefinitionType',
        Title          : 'Incidents by Urgency',
        ChartType      : #Donut,
        Dimensions     : [urgency_name],
        DynamicMeasures: ['@Analytics.AggregatedProperty#urgency_count_sum']
    },
    UI.PresentationVariant                         : {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: [
            '@UI.Chart',
            '@UI.LineItem'
        ]
    },
    UI.LineItem                                    : [
        {
            $Type: 'UI.DataField',
            Value: urgency_name,
            Label: 'Urgency'
        },
        {
            $Type: 'UI.DataField',
            Value: count,
            Label: 'Count'
        }
    ]
);

annotate service.IncidentsByUrgency with {
    urgency_name @Common.Label: 'Urgency';
};
