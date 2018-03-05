resource "aws_instance" "bootnode" {
  count                       = "${var.bootnode_count_instances}"
  ami                         = "${var.image}"
  instance_type               = "${var.bootnode_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.bootnode-ec2.id}"]
  associate_public_ip_address = true
  availability_zone           = "${var.region}a"
  key_name                    = "${var.awskeypair_name}"

  root_block_device {
        volume_type = "gp2"
        volume_size = 20
        delete_on_termination = "true"
    }

  ebs_block_device {
        device_name = "/dev/sda1"
        volume_type = "gp2"
        volume_size = 128
        delete_on_termination = "true"
      }

  tags {
    Name                 = "${var.bootnode_instance_name}"
  }
}

resource "aws_instance" "bootnode-elb" {
  count                       = "${var.bootnode-elb_count_instances}"
  ami                         = "${var.image}"
  instance_type               = "${var.bootnode-elb_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.bootnode-ec2.id}"]
  availability_zone           = "${element(var.availability_zones, count.index)}"
  associate_public_ip_address = true
  key_name                    = "${var.awskeypair_name}"

  root_block_device {
        volume_type = "gp2"
        volume_size = 20
        delete_on_termination = "true"
    }

  ebs_block_device {
        device_name = "/dev/sda1"
        volume_type = "gp2"
        volume_size = 128
        delete_on_termination = "true"
      }

  tags {
    Name                 = "${var.bootnode-elb_instance_name}"
  }
}

resource "aws_instance" "mining" {
  count                       = "${var.mining_count_instances}"
  ami                         = "${var.image}"
  instance_type               = "${var.mining_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.mining-ec2.id}"]
  associate_public_ip_address = true
  availability_zone           = "${var.region}b"
  key_name                    = "${var.awskeypair_name}"

  root_block_device {
        volume_type = "gp2"
        volume_size = 20
        delete_on_termination = "true"
    }

  ebs_block_device {
        device_name = "/dev/sda1"
        volume_type = "gp2"
        volume_size = 128
        delete_on_termination = "true"
    }

  tags {
    Name                 = "${var.mining_instance_name}"
  }
}

resource "aws_instance" "owner" {
  count                       = "${var.owner_count_instances}"
  ami                         = "${var.image}"
  instance_type               = "${var.owner_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.owner-ec2.id}"]
  associate_public_ip_address = true
  availability_zone           = "${var.region}c"
  key_name                    = "${var.awskeypair_name}"

  root_block_device {
        volume_type = "gp2"
        volume_size = 20
        delete_on_termination = "true"
    }

  ebs_block_device {
        device_name = "/dev/sda1"
        volume_type = "gp2"
        volume_size = 128
        delete_on_termination = "true"
    }

  tags {
    Name                 = "${var.owner_instance_name}"
  }
}
