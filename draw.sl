@sl.component
def draw(stacks, show_diff_only, also_show_cstn_params, transposed=True):
    filter_regex = sl.use_reactive("")
    filter_exception = sl.use_reactive("")

    def convert(value):
        na_result = pd.isna(value)
        if isinstance(na_result, bool) and na_result:
            return ""
        if isinstance(value, bool):
            return "true" if value else "false"
        return str(value)

    stack_names = set()
    for v in stacks:
        for s in v:
            stack_names.add(s["configurationConfig.name"][0])
    sorted_stack_names = sorted(list(stack_names))
    dfs = []
    for stack_name in sorted_stack_names:
        df = pd.DataFrame()
        for v in stacks:
            matched_stack = [
                s for s in v if s["configurationConfig.name"][0] == stack_name
            ]
            if len(matched_stack) > 0:
                df = pd.concat([df, matched_stack])

        only_single_stack = len(df) == 1
        if not only_single_stack and show_diff_only:
            for column in df.columns:
                if len(df[column].apply(convert).unique()) == 1:
                    del df[column]

        df.set_index("id", inplace=True)
        if not also_show_cstn_params:
            overrides = [
                column
                for column in df.columns
                if column.endswith("overridesParentParameters")
            ]
            columns_to_drop = [
                item for item in cstn_param_names + overrides if item in df.columns
            ]
            df = df.drop(columns=columns_to_drop)
        no_columns = len(df.columns) == 0
        if transposed:
            df = df.T

        if not show_diff_only:
            df = df.style.apply(
                lambda x: [
                    "background: yellow" if len(x.apply(convert).unique()) > 1 else ""
                    for _ in x
                ],
                axis=1 if transposed else 0,
            )

        dfs.append((stack_name, df if not no_columns else None))

    with sl.Row():
        sl.Button("Expand All", on_click=lambda: expanded_panels.set(all_panel_indexes))
        sl.Button("Fold All", on_click=lambda: expanded_panels.set([]))
        sl.InputText(
            "Stack Name Regex",
            value=filter_regex,
            continuous_update=True,
            message=filter_exception.value,
        )

    pattern = re.compile("")
    try:
        pattern = re.compile(filter_regex.value, re.IGNORECASE)
        filter_exception.set("")
    except Exception as e:
        filter_exception.set(repr(e))

    same_stacks = []
    for name, df in dfs:
        if df is None:
            same_stacks.append(name)
    with sl.Card("Identical Stacks"):
        sl.DataFrame(pd.DataFrame({"stack_id": same_stacks}))

    filtered_dfs = [
        (name, df) for name, df in dfs if len(re.findall(pattern, name)) > 0
    ]

    all_panel_indexes = [i for i in range(len(filtered_dfs))]
    expanded_panels = sl.use_reactive(all_panel_indexes)
    with rv.ExpansionPanels(multiple=True, popout=True, value=expanded_panels.get()):
        for name, df in filtered_dfs:
            if df is None:
                continue
            with rv.ExpansionPanel():
                with rv.ExpansionPanelHeader():
                    sl.Markdown(f"**{name}**")
                with rv.ExpansionPanelContent():
                    sl.display(df)
