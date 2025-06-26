@sl.component
def HistoricalConfigSelector():
    deployment = sl.use_reactive("")
    stack_group = sl.use_reactive("")
    date = sl.use_reactive("")
    time = sl.use_reactive("")
    selected_updated = sl.use_reactive(False)

    def update_selected_configs():
        configs_to_add = dict()
        config_to_remove = {key for key in historical_configs.value}
        for config in selected.value:
            if config["id"] in historical_configs.value:
                config_to_remove.remove(config["id"])
            else:
                conf = {
                    "raw": download_from_csm_api(config["id"]),
                    "editdiff": get_config("raw")
                }
                configs_to_add[config["id"]] = conf
        for config_id in config_to_remove:
            historical_configs.value.pop(config_id, None)
        for config_id, conf in configs_to_add.items():
            historical_configs.value[config_id] = conf
        selected_updated.set(False)
        return configs_to_add, config_to_remove

    historical_configs_result = sl.lab.use_task(
        update_selected_configs, dependencies=[selected_updated.value]
    )

    if historical_configs_result.finished and not selected_updated.value:
        stacks_to_add, stacks_to_remove = historical_configs_result.value
        current_historical_results = {}
        for k, v in historical_configs.value.items():
            if k not in stacks_to_remove:
                current_historical_results[k] = v
        selected_updated.set(True)

    all_configs_result = sl.lab.use_task(
        get_all_configs_from_csm, dependencies=[sl.get_kernel_id()]
    )
    if not all_configs_result.finished:
        return

    headers = [
        {"text": "Deployment", "value": "deployment"},
        {"text": "Stack Group", "value": "stack_group"},
        {"text": "Date", "value": "date_id"},
        {"text": "Time", "value": "time_str"},
    ]

    with sl.Row():
        sl.InputText("Deployment", value=deployment, continuous_update=True)
        sl.InputText("Stack Group", value=stack_group, continuous_update=True)
        sl.InputText("Date", value=date, continuous_update=True)
        sl.InputText("Time", value=time, continuous_update=True)

    configs = [dataclasses.asdict(config) for config in all_configs_result.value]

    def match(config):
        return (
            deployment.value in config["deployment"]
            and stack_group.value in config["stack_group"]
            and date.value in config["date_id"]
            and time.value in config["time_str"]
        )

    configs = sorted(
        [config for config in configs if match(config)],
        key=lambda cfg: cfg["date_id"] + cfg["time_str"],
        reverse=True,
    )

    rv.DataTable(
        v_model=selected.value,
        on_v_model=selected.set,
        headers=headers,
        items=configs,
        items_per_page=20,
        to_select=True,
        selectable_key="id",
    )
