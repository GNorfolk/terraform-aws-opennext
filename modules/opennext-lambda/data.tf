data "archive_file" "lambda_zip" {
  type = "zip"

  source_dir  = var.source_dir
  output_path = "${var.output_dir}${var.prefix}.zip"
}

data "aws_vpc" "this" {
  count = var.vpc_id == null ? 0 : 1
  id    = var.vpc_id
}

data "aws_subnets" "this" {
  count = var.vpc_id == null ? 0 : 1
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this[0].id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = [var.subnet_map_public_ip]
  }
  dynamic "filter" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      name   = "subnet-id"
      values = var.subnet_ids
    }
  }
}
