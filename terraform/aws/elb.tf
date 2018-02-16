
resource "aws_elb" "elb" {
  name                = "bootnodes"
  availability_zones  = "${var.availability_zones}"
  security_groups     = ["${aws_security_group.bootnode-elb.id}"]


  listener {
    instance_port     = 8545
    instance_protocol = "TCP"
    lb_port           = 8545
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8545"
    interval            = 5
  }

  instances           = ["${aws_instance.bootnode-elb.*.id}"]

  tags {
    Name = "bootnode-elb"
  }
}
