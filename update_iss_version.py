import yaml
import re

# Read the version from pubspec.yaml
with open('pubspec.yaml', 'r') as file:
    pubspec = yaml.safe_load(file)
    version = pubspec['version']

# Update the version in installer.iss
with open('installer.iss', 'r') as file:
    content = file.read()

# Replace the version in the [Setup] section
content = re.sub(r'AppVersion=.*', f'AppVersion={version}', content)

# Replace the version in the [Registry] section
content = re.sub(r'ValueData: ".*"', f'ValueData: "{version}"', content)

# Replace the version in the [Code] section
content = re.sub(r"const\s+MyAppVersion\s+=\s+'.*';", f"const MyAppVersion = '{version}';", content)

with open('installer.iss', 'w') as file:
    file.write(content)