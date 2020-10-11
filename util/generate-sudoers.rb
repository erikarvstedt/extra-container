# 1. Add $HOME/.nix-profile/bin to secure_path (Defaults)
# 2. Add NIX_PATH to env_keep (Defaults)
#
def make_sudoers(old_sudoers, extra_secure_paths)
  secure_path_set = false

  sudoers = old_sudoers.sub(/(Defaults\s+secure_path\s*=\s*"?)([^"\s]+)(.*)/) do |_|
    secure_path_set = true
    prefix, path, suffix = $1, $2, $3
    paths = path.split(':')
    extra_paths = extra_secure_paths.split(':')
    new_path = (paths + extra_paths).uniq.join(':')
    "#{prefix}#{new_path}#{suffix}"
  end

  env_keep_statement = "Defaults	env_keep += NIX_PATH"

  lines_to_add = []
  lines_to_add << %(Defaults	secure_path = "#{extra_secure_paths}") if !secure_path_set
  lines_to_add << env_keep_statement if !old_sudoers.include?(env_keep_statement)

  if !lines_to_add.empty?
    sudoers << lines_to_add.join("\n") << "\n"
  end

  sudoers == old_sudoers ? nil : sudoers
end

if __FILE__ == $0
  puts make_sudoers(STDIN.read, ARGV.first)
end
