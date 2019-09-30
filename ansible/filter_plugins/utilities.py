class FilterModule:

    def filters(self):
        return {
            'user_home': self.user_home
        }

    def user_home(self, d, username):
        for user in d["results"]:
            if user["item"] == username:
                return user["home"]
        return ValueError("Cannot find the home directory for user {}".format(username))
