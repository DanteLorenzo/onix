dconf read /org/gnome/Ptyxis/default-profile-uuid

That will give you the UUID. Copy that.
You can also go to the profile and copy it from there.

Then run this command to write the dconf key.

dconf write /org/gnome/Ptyxis/Profiles/3aae5a177777aa966b1fd63467153e2d/opacity 0.85