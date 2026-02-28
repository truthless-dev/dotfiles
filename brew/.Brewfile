instance_eval(File.read(File.expand_path(".Brewfile.common", __dir__)))

case ENV["MACHINE_ROLE"]
when "personal"
    instance_eval(File.read(File.expand_path(".Brewfile.personal", __dir__)))
when "work"
    instance_eval(File.read(File.expand_path(".Brewfile.work", __dir__)))
    else
    instance_eval(File.read(File.expand_path(".Brewfile.personal", __dir__)))
end
