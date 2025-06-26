@sl.component
def ZipViewer(zip_data):
    show_diff = sl.use_reactive(False)

    zip_obj = io.BytesIO(zip_data)
    sl.Button("Show Files", on_click=lambda: show_diff.set(True))
    with rv.Dialog(
        v_model=show_diff.value,
        max_width="2000px",
        scrollable=True,
        on_v_model=lambda v: show_diff.set(v),
    ):
        with rv.Sheet(min_height="1500px"):
            with zipfile.ZipFile(zip_obj, "r") as zip_file:
                with rv.Tabs(
                    color="indigo", vertical=True, style_="margin: 0px; padding:0x"
                ):
                    for file_name in zip_file.namelist():
                        rv.Tab(class_="text-none", children=[file_name])
                        with zip_file.open(file_name) as file:
                            file_data = file.read()
                            with rv.TabItem(transition=False, reverse_transition=False):
                                sl.Markdown(
                                    f"```{file_name.split('.')[-1]}\n{file_data.decode('utf-8')}\n```"
                                )
