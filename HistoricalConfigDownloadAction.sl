@sl.component
def HistoricalConfigDownloadAction(historical_config_binary, file_name):
    attrs = sl.use_reactive(get_sim_file_attributes(historical_config_binary))
    show_download_options = sl.use_reactive(False)
    split_book_toggle = sl.use_reactive(True)
    should_overwrite_feed_depth = sl.use_reactive(True)
    should_remove_thread_name_if_empty = sl.use_reactive(True)
    overwrite_feed_depth = sl.use_reactive(15)
    should_overwrite_underlying = sl.use_reactive(
        not attrs.value.get("has_underlying", False)
    )
    overwrite_underlying_text = sl.use_reactive(
        attrs.value.get("base_book", ["not detected"])[0]
    )
    sort_stack_config_toggle = sl.use_reactive(True)

    sl.Button("Download Zip", on_click=lambda: show_download_options.set(True))

    with rv.Dialog(
        v_model=show_download_options.value,
        max_width="800px",
        scrollable=True,
        on_v_model=lambda v: show_download_options.set(v),
    ):
        with sl.Column(align="stretch"):
            with sl.Row():
                sl.Switch(
                    label="feed_factories.json: overwrite output_book_depth",
                    value=should_overwrite_feed_depth,
                )
                sl.InputInt(
                    "output book depth to overwrite",
                    value=overwrite_feed_depth,
                    continuous_update=True,
                    disabled=not should_overwrite_feed_depth.value,
                )
                sl.Switch(
                    label="stack_configs.json: remove thread field from config if empty",
                    value=should_remove_thread_name_if_empty,
                )
                sl.Switch(
                    label="feed_factories.json: split book factory to per book",
                    value=split_book_toggle,
                )
                sl.Switch(
                    label="stack_configs.json: Sort stacks by name",
                    value=sort_stack_config_toggle,
                )
            with sl.Row():
                sl.Switch(
                    label="stack_configs.json: overwrite underlying book",
                    value=should_overwrite_underlying,
                )
                sl.InputText(
                    "underlying book to overwrite/fill",
                    value=overwrite_underlying_text,
                    continuous_update=True,
                    disabled=not should_overwrite_underlying.value,
                )

    overwrite_function_map = defaultdict(list)
    if split_book_toggle.value:
        overwrite_function_map["feed_factories.json"].append(split_book_factory)
    if should_overwrite_feed_depth.value:
        overwrite_function_map["feed_factories.json"].append(
            lambda config, depth=overwrite_feed_depth.value: overwrite_feed_factory_output_book_depth(
                config, depth
            )
        )
    if should_remove_thread_name_if_empty.value:
        overwrite_function_map["stack_configs.json"].append(
            remove_thread_field_if_empty
        )
    if should_overwrite_underlying.value:
        overwrite_function_map["stack_configs.json"].append(
            lambda config, underlying=overwrite_underlying_text.value: overwrite_underlying(
                config, underlying
            )
        )
    if sort_stack_config_toggle.value:
        overwrite_function_map["stack_configs.json"].append(
            lambda config: sort_stacks(config)
        )

    with sl.Column():
        for stack_name, forest_config in attrs.value.get("forest_info", []):
            ForestDownloader(stack_name, forest_config)

    zip_to_download = modify_files_in_zip(
        overwrite_function_map, historical_config_binary
    )

    sl.FileDownload(
        zip_to_download,
        filename=file_name,
        label="Download Config",
    )
