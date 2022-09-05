import re
import secrets
import base64
import crypt

_SHA512_PREFIX     = "$6$"
# Limits taken from crypt(5) on Arch
_SHA512_SALT_BYTES = 12
_SHA512_MIN_ROUNDS = 10**3
_SHA512_MAX_ROUNDS = 10**9 - 1

class FilterModule:

    def filters(self):
        return {
            'user_home': self.user_home,
            'split_partition_number': self.split_partition_number,
            'sha512_hash': self.sha512_hash
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

    def sha512_hash(self, pw, rounds):
        if not _SHA512_MIN_ROUNDS <= rounds <= _SHA512_MAX_ROUNDS:
            raise ValueError("sha512 password hashing requires a rounds value between "
                f"{ _SHA512_MIN_ROUNDS } and { _SHA512_MAX_ROUNDS }")
        salt = base64.b64encode(secrets.token_bytes(_SHA512_SALT_BYTES)).decode("utf-8")
        return crypt.crypt(pw, f"{ _SHA512_PREFIX }rounds={ rounds }${ salt }")

