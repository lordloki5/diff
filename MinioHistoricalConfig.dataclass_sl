@dataclass
class MinioHistoricalConfig:
    id: str
    deployment: str
    stack_group: str
    date_id: str
    time_str: str

    def __init__(self, name: str):
        self.id = name
        split_list = name.split("/")
        self.deployment = split_list[0]
        self.stack_group = split_list[1]
        zip_name = split_list[-1]
        self.date_id, self.time_str = zip_name[len(self.stack_group) + 1 : -4].split("T")
