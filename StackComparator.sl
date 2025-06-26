@sl.component
def StackComparator(selected_stack_group_contexts):
    group_stacks_storage = sl.use_reactive(dict())
    new_configs_downloaded = sl.use_reactive(False)

    def download_configs():
        group_stacks_to_add = dict()
        group_stacks_to_remove = {key for key in group_stacks_storage.value}
        for (deployment, group_name), context in selected_stack_group_contexts.value.items():
            key = (deployment, group_name)
            if key in group_stacks_to_remove:
                group_stacks_to_remove.remove(key)
            if key in group_stacks_storage.value:
                continue
            group_stacks_to_add[key] = _get_stacks_for_url(
                tuple(sorted(context.stack_config_urls_for(group_name)))
            )

        if len(group_stacks_to_add) > 0 or len(group_stacks_to_remove) > 0:
            new_configs_downloaded.set(False)
        return group_stacks_to_add, group_stacks_to_remove

    new_stacks = sl.lab.use_task(
        download_configs, dependencies=[selected_stack_group_contexts.value]
    )
    if new_stacks.finished and not new_configs_downloaded.value:
        stacks_to_add, stacks_to_remove = new_stacks.value
        current_group_stacks = {
            k: v
            for k, v in group_stacks_storage.value.items()
            if k not in stacks_to_remove
        }
        current_group_stacks.update(stacks_to_add)
        group_stacks_storage.set(current_group_stacks)
        new_configs_downloaded.set(True)
        print(f"selected groups keys {group_stacks_storage.value.keys()}")

    sl.ProgressLinear(not new_stacks.finished)
    diff_only = sl.use_reactive(True)
    show_cstn = sl.use_reactive(False)
    ignore_books = sl.use_reactive(False)
    book_id_regex = sl.use_reactive(r"(cu|[1][\w\-\s]+(?:[c]|[s]|[u])*)")

    with sl.Row():
        sl.Switch(label="Show Diff Only", value=diff_only)
        sl.Switch(label="Show CSTN field", value=show_cstn)
        sl.Switch(label="Ignore Books", value=ignore_books)
        sl.InputText(
            "Book ID regex", value=book_id_regex, disabled=not ignore_books.value
        )

    live_stacks = list(group_stacks_storage.value.values())

    def convert_cstn_configs_to_cfsh_format():
        group_stacks = []
        for configs in group_stacks_storage.value.values():
            stacks = []
            for stack in configs:
                rename_dict = dict()
                for column in stack.columns:
                    if (
                        isinstance(stack[column][0], list)
                        and len(stack[column][0]) > 0
                        and all(
                            not isinstance(value, str) for value in stack[column][0]
                        )
                    ):
                        stack[column][0] = ",".join([str(v) for v in stack[column][0]])

                    if (
                        column == "labels.pricing_labels.pricing_publishers"
                        or column == "stack_details.val_publisher.valuation_book"
                    ):
                        stack.drop([column], axis=1, inplace=True)
                        continue
                    splits = column.split(".")
                    if splits[0] == "params":
                        new_column_name = f"config.{splits[1][:-7]}.{splits[-1]}"
                        rename_dict[column] = new_column_name
                    elif splits[0] == "labels":
                        if splits[1] == "internal_labels":
                            if splits[2] == "loginternal":
                                rename_dict[column] = f"mappings.{splits[-1]}.label"
                            elif splits[2] == "multiinternal":
                                rename_dict[column] = f"mappings.{splits[-1]}.labels"
                            else:
                                rename_dict[column] = f"mappings.{splits[-1]}.value"
                        elif "internal_labels" in splits:
                            stack[f"mappings.{splits[-1]}.type"] = re.sub(
                                r"valuation", "", splits[-2]
                            )
                        else:
                            stack[f"mappings.{splits[-1]}.type"] = "external"
                    stack.rename(columns=rename_dict, inplace=True)
                    columns_to_remove = [
                        column
                        for column in stack.columns
                        if "overrideParentParameters" in column
                    ]
                    stack.drop(columns_to_remove, axis=1, inplace=True)
                stacks.append(stack)
            group_stacks.append(stacks)
        return group_stacks

    def convert_historical_configs_to_dataframe():
        stacks = []
        for config in historical_configs.value.values():
            dfs = []
            for stack_name, stack_config_details in config["details"].items():
                details = stack_config_details
                details["configurationConfig.name"] = stack_name
                details["id"] = f"{config['id']}.{stack_name}"
                df = pd.json_normalize(details)
                if len(df.columns) > 0:
                    for col in df.columns:
                        df.rename(
                            columns={"thread"+"configurationConfig.threadName"},
                            inplace=True,
                        )
                    df.drop(["stack"], axis=1, inplace=True)
                    dfs.append(df)
            stacks.append(dfs)
        return stacks

    historical_stack_list = convert_historical_configs_to_dataframe()
    if len(live_stacks) > 0 and len(historical_stack_list) > 0:
        live_stacks = convert_cstn_configs_to_cfsh_format()

    all_configs = live_stacks + historical_stack_list
    if ignore_books.value:
        for group_config in all_configs:
            for config in group_config:
                for column in config.columns:
                    value = config[column][0]
                    if isinstance(value, str):
                        config[column][0] = re.sub(book_id_regex.value, "", value)
                    elif isinstance(value, list) and all(
                        isinstance(v, str) for v in value
                    ):
                        config[column][0] = [
                            re.sub(book_id_regex.value, "", v) for v in value
                        ]

    draw(
        all_configs,
        show_diff_only=diff_only.value,
        also_show_cstn_params=show_cstn.value,
        transpose=True,
    )

    execution_state.print_state()
