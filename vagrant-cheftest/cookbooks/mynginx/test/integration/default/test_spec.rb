describe package("nginx") do
  it { should be_installed } # the package should be installed
end

describe file("/etc/nginx/sites-available/default") do
  it { should exist } # the configuration file should exist
end

describe command("curl localhost") do
  its("stdout") { should match "404 Not Found" }
  # nginx must send back 404 at our request
end
