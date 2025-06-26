@sl.component
def ForestDownloader(stack_name, forest_config):
    should_download = sl.use_reactive(False)

    def download_forest():
        if not should_download.value:
            return None
        required_fields = {"bucket", "location"}
        if not all(field in forest_config for field in required_fields):
            return {
                "error": f"not all required fields {required_fields} found in {forest_config}"
            }
        forest_model = download_model_from_csm_api(
            forest_config["bucket"], forest_config["location"]
        )
        forest_file_name = forest_config["location"]
        if "original_parameter" in forest_config:
            forest_file_name += "-" + forest_config["original_parameter"]["location"]
        return dict(content=forest_model, name=forest_file_name)

    download_result = sl.lab.use_task(
        download_forest, dependencies=[should_download.value]
    )

    with sl.Card(stack_name):
        with sl.Card("Model Path"):
            if "original_parameter" in forest_config:
                sl.Markdown(forest_config["original_parameter"]["location"])
                sl.Markdown(f"Backup Model Path: {forest_config['location']}")
            else:
                sl.Markdown(forest_config["location"])
        with sl.Row():
            sl.Switch(label="show model download button", value=should_download)
            if not download_result.finished:
                sl.ProgressLinear(True)
            elif download_result.value is not None:
                if "error" in download_result.value:
                    sl.Error(download_result.value["error"])
                else:
                    sl.FileDownload(
                        download_result.value["content"],
                        filename=download_result.value["name"],
                        label="Download Model",
                    )
