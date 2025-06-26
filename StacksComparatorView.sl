@sl.component
def StacksComparatorView(selected_stack_group_contexts):
    with rv.ExpansionPanels():
        with rv.ExpansionPanel():
            with rv.ExpansionPanelHeader():
                sl.Markdown("**Historical Config Selector**")
            with rv.ExpansionPanelContent():
                HistoricalConfigSelector()
    if (
        len(selected_stack_group_contexts.value) != 0
        or len(historical_configs.value) != 0
    ):
        with sl.Card():
            DiffContainer(selected_stack_group_contexts)
            with sl.Card():
                StacksComparator(selected_stack_group_contexts)
    else:
        with sl.Card("Stack Group Comparator"):
            sl.Markdown(
                "No stacks have been selected, please select from the other tab"
            )
