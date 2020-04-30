import re

class FilterModule:

    def filters(self):
        return {
            'user_home': self.user_home,
            'split_partition_number': self.split_partition_number
        }

    def user_home(self, d, username):
        for user in d["results"]:
            if user["item"] == username:
                return user["home"]
        raise ValueError("Cannot find the home directory for user {}".format(username))


    def split_partition_number(self, devnode):
        # Matches things like /dev/mmcblk0p1 or /dev/sda1
        match = re.search(r"(?:(\d+)p)?(\d+)$", devnode)
        if match is None:
            raise ValueError("Cannot extract a partition number from device node {}".format(devnode))
        part = int(match.group(2))
        dev = "{}{}".format(
            devnode[:-len(match.group(0))],
            match.group(1) or ""
        )
        return (dev, part)