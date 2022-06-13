resource "aws_instance" "dev_server" {
  ami                         = "ami-02c3627b04781eada" // Amazon Linux 2 Kernel 5.10 AMI 2.0.20220426.0 x86_64 HVM gp2
  instance_type               = "t3.small"
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.ec2_for_ssm.name
  associate_public_ip_address = true
  key_name                    = "m-kanno"

  tags = {
    Name = "m-kanno-dev-server"
  }
}

variable "subnet_id" {
  type = string
}

data "aws_iam_policy_document" "ec2_for_ssm" {
  statement {
    effect = "Allow"
    resources = [
      aws_instance.dev_server.arn,
    ]

    actions = [
      "ssm:StartSession",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
      "ssm:DescribeInstanceProperties",
      "ec2:DescribeInstances",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ssm:*:*:session/$${aws:username}-*"]

    actions = [
      "ssm:TerminateSession",
      "ssm:ResumeSession"
    ]
  }
}

module "ec2_for_ssm_role" {
  source     = "./modules/iam_role"
  name       = "m-kanno-ec2-for-ssm"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.ec2_for_ssm.json
}

resource "aws_iam_instance_profile" "ec2_for_ssm" {
  name = "m-kanno-ec2-for-ssm"
  role = module.ec2_for_ssm_role.iam_role_name
}
