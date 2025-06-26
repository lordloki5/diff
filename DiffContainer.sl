@sl.component
def DiffContainer(diff_groups):
    with rv.Container():
        with sl.Row():
            for deployment, group in diff_groups.value.keys():
                with sl.Card(f"Deployment: {deployment}"):
                    sl.Markdown(f"# Stack group: **{group}**")
                    with sl.CardActions():

                        def remove_from_selection(key):
                            if key in diff_groups.value:
                                diff_groups.value = {
                                    k: v
                                    for k, v in diff_groups.value.items()
                                    if k != key
                                }

                        sl.Button(
                            "remove",
                            on_click=lambda k=(
                                deployment,
                                group,
                            ): remove_from_selection(k),
                        )

        for _, historical_config in historical_configs.value.items():
            with sl.Card(f"Deployment: {historical_config['deployment']}"):
                sl.Markdown(
                    f"# Stack group: **{historical_config['stack_group']}**"
                )
                sl.Markdown(f"Date: **{historical_config['date_id']}**")
                sl.Markdown(f"Time: **{historical_config['time_str']}**")
                with sl.CardActions():

                    def remove_historical_config_from_selection(key):
                        historical_configs.value = {
                            config_id: config
                            for config_id, config in historical_configs.value.items()
                            if config_id != key
                        }
                        selected.value = [
                            config
                            for config in selected.value
                            if key != config["id"]
                        ]

                    sl.Button(
                        "remove",
                        on_click=lambda k=historical_config["id"]: remove_historical_config_from_selection(k),
                    )

                HistoricalConfigDownloadAction(
                    historical_config["raw"],
                    f"{historical_config['deployment']}_{historical_config['stack_group']}_{historical_config['date_id']}_{historical_config['time_str']}.zip",
                )
                ZipViewer(historical_config["raw"])
