import reflex as rx

# === State class ===
class AppState(rx.State):
    selected_stack_group_contexts: list = []
    historical_configs: list = []

# === Placeholder Components ===
def HistoricalConfigSelector():
    return rx.text("Historical Config Selector Component")

def DiffContainer(selected_stack_group_contexts):
    return rx.text("DiffContaineritems")

def StacksComparator(selected_stack_group_contexts):
    return rx.text("StacksComparator items")

# === Main View Component ===
def StacksComparatorView():
    return rx.vstack(
        rx.accordion.root(
            rx.accordion.item(
                value="historical-config",
                header=rx.markdown("**Historical Config Selector**"),
                content=HistoricalConfigSelector(),
            ),
            type="single",
            collapsible=True,
        ),
        rx.cond(
            AppState.selected_stack_group_contexts | AppState.historical_configs,
            rx.card(
                rx.card(
                    DiffContainer(AppState.selected_stack_group_contexts)
                ),
                rx.card(
                    StacksComparator(AppState.selected_stack_group_contexts)
                ),
            ),
            rx.card(
                rx.markdown(
                    "No stacks have been selected, please select from the other tab"
                ),
                header="Stack Group Comparator"
            ),
        ),
    )

# === App Setup ===
app = rx.App()
app.add_page(StacksComparatorView, "/" ,title="Stacks Comparator")
