locals {
  requirements_hash = filemd5("${path.module}/function_code/requirements.txt")
}

# Run pip install whenever requirements.txt changes.
resource "null_resource" "pip_install" {
  triggers = {
    requirements = local.requirements_hash
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/function_code"
    command     = "python -m pip install --target=.python_packages/lib/site-packages --platform manylinux2014_x86_64 --python-version 3.11 --only-binary=:all: --upgrade -r requirements.txt"
  }
}