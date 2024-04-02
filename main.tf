variable "token_key" {
  type = string
}

variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

terraform {
    required_providers {
      yandex = {
        source = "yandex-cloud/yandex"
      }
    }
    required_version = ">= 0.13"
}
  
provider "yandex" {
    token     = var.token_key
    cloud_id  = var.cloud_id
    folder_id = var.folder_id
    zone      = "ru-central1-a"
}

variable "private_key_path" {
  type = string
  default = "/home/diplom-kostyuk/.ssh/id_rsa"
}

data "yandex_compute_image" "lemp" {
    family = "lemp"
}

data "yandex_compute_image" "nat-instance-ubuntu" {
    family = "nat-instance-ubuntu"
}

/*
 * ---------------------------------------------------------------------------
 * Создаем виртуальную машину vm-1 в зоне ru-central1-a
 * ---------------------------------------------------------------------------
 */

resource "yandex_compute_instance" "vm-1" {
  name = "vm-1"
  allow_stopping_for_update = true
  zone = "ru-central1-a"
  depends_on = [yandex_compute_instance.bastion]

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

#  scheduling_policy {
#    preemptible = true
#  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.lemp.id
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_1.id
    security_group_ids = [yandex_vpc_security_group.only_internal.id]
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

/*
 * ---------------------------------------------------------------------------
 * Создаем виртуальную машину vm-2 в зоне ru-central1-b
 * ---------------------------------------------------------------------------
 */

resource "yandex_compute_instance" "vm-2" {
  name = "vm-2"
  allow_stopping_for_update = true
  zone = "ru-central1-b"
  depends_on = [yandex_compute_instance.bastion]

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

#  scheduling_policy {
#    preemptible = true
#  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.lemp.id
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_2.id
    security_group_ids = [yandex_vpc_security_group.only_internal.id]
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

/*
 * ---------------------------------------------------------------------------
 * Создаем Zabbix-server в зоне ru-central1-b
 * ---------------------------------------------------------------------------
 */

 resource "yandex_compute_instance" "vm-zabbix" {
  name = "vm-zabbix"
  allow_stopping_for_update = true
  zone = "ru-central1-a"
  depends_on = [yandex_compute_instance.bastion]

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

#  scheduling_policy {
#    preemptible = true
#  }

  boot_disk {
    initialize_params {
       image_id = "fd8tg1klri45q94qn8dt"
       size = 5
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_4.id
    security_group_ids = [yandex_vpc_security_group.only_internal.id, yandex_vpc_security_group.public_zabbix.id]
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

/*
 * ---------------------------------------------------------------------------
 * Создаем виртуальную машину Elasticsearch в зоне ru-central1-a
 * ---------------------------------------------------------------------------
 */

resource "yandex_compute_instance" "es" {
  name = "es"
  allow_stopping_for_update = true
  zone = "ru-central1-b"
  depends_on = [yandex_compute_instance.bastion]

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

#  scheduling_policy {
#    preemptible = true
#  }

  boot_disk {
    initialize_params {
      image_id = "fd8vbtqkqb6fhhksv1p4"
      size = 10
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_3.id
    security_group_ids = [yandex_vpc_security_group.only_internal.id]
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

/*
 * ---------------------------------------------------------------------------
 * Создаем виртуальную машину Kibana в зоне ru-central1-a
 * ---------------------------------------------------------------------------
 */

resource "yandex_compute_instance" "kibana" {
  name = "kibana"
  allow_stopping_for_update = true
  zone = "ru-central1-a"
  depends_on = [yandex_compute_instance.bastion]

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

#  scheduling_policy {
#    preemptible = true
#  }

  boot_disk {
    initialize_params {
      image_id = "fd8tg1klri45q94qn8dt"
      size = 10
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_4.id
    security_group_ids = [yandex_vpc_security_group.only_internal.id, yandex_vpc_security_group.public_kibana.id]
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

/*
 * ---------------------------------------------------------------------------
 * Создаем виртуальную машину Bastion в зоне ru-central1-a
 * ---------------------------------------------------------------------------
 */

resource "yandex_compute_instance" "bastion" {
  name = "bastion"
  allow_stopping_for_update = true
  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

#  scheduling_policy {
#    preemptible = true
#  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.nat-instance-ubuntu.id
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_4.id
    security_group_ids = [yandex_vpc_security_group.only_internal.id, yandex_vpc_security_group.ssh_bastion.id]
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

/*
 * ---------------------------------------------------------------------------
 *               Сетки
 * ---------------------------------------------------------------------------
 */

resource "yandex_vpc_network" "network_terraform" {
  name = "network_terraform"
}

resource "yandex_vpc_route_table" "private-nat" {
  network_id = yandex_vpc_network.network_terraform.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.bastion.network_interface.0.ip_address
  }
}

# ---------------------------------------------------------------------------

resource "yandex_vpc_subnet" "subnet_1" {
  name           = "subnet_1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network_terraform.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  route_table_id = yandex_vpc_route_table.private-nat.id
}

resource "yandex_vpc_subnet" "subnet_2" {
  name           = "subnet_2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network_terraform.id
  v4_cidr_blocks = ["192.168.2.0/24"]
  route_table_id = yandex_vpc_route_table.private-nat.id
}

#---------- Elasticsearch
resource "yandex_vpc_subnet" "subnet_3" {
  name           = "subnet_3"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network_terraform.id
  v4_cidr_blocks = ["192.168.3.0/24"]
  route_table_id = yandex_vpc_route_table.private-nat.id
}

#---------- Balanser & Zabbix & Kibana & Bastion
resource "yandex_vpc_subnet" "subnet_4" {
  name           = "subnet_4"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network_terraform.id
  v4_cidr_blocks = ["192.168.4.0/24"]
}

#---------------------------------------------------------------------------------------------------------------------------
#----------------- security_group -----------------
resource "yandex_vpc_security_group" "only_internal" {
  name       = "only_internal"
  network_id = yandex_vpc_network.network_terraform.id

  ingress {
    protocol       = "ANY"
    description    = "allow any connection only from internal subnets"
    v4_cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connections"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#----------------- bastion_rules ---------------------------------------
resource "yandex_vpc_security_group" "ssh_bastion" {
  name       = "ssh_bastion"
  network_id = yandex_vpc_network.network_terraform.id

  ingress {
    protocol       = "TCP"
    description    = "allow ssh connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#----------------- Kibana_rules ---------------------------------------
resource "yandex_vpc_security_group" "public_kibana" {
  name       = "public_kibana"
  network_id = yandex_vpc_network.network_terraform.id

  ingress {
    protocol       = "TCP"
    description    = "allow kibana connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#----------------- Zabbix_rules ---------------------------------------
resource "yandex_vpc_security_group" "public_zabbix" {
  name       = "public_zabbix"
  network_id = yandex_vpc_network.network_terraform.id

  ingress {
    protocol       = "TCP"
    description    = "allow zabbix connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


#----------------- Yandex Application Load Balancer rules ---------------------------------------
resource "yandex_vpc_security_group" "public-alb" {
  name       = "public-alb"
  network_id = yandex_vpc_network.network_terraform.id

  ingress {
    protocol          = "ANY"
    description       = "Health checks"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol       = "TCP"
    description    = "allow HTTP connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

/*
 * ---------------------------------------------------------------------------
 *       Yandex Application Load Balancer
 * ---------------------------------------------------------------------------
 */


#----------------- target_group -----------------

resource "yandex_alb_target_group" "web-servers-target-group" {
  name = "web-servers-target-group"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet_1.id}"
    ip_address = "${yandex_compute_instance.vm-1.network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.subnet_2.id}"
    ip_address = "${yandex_compute_instance.vm-2.network_interface.0.ip_address}"
  }
}

#----------------- backend_group -----------------

resource "yandex_alb_backend_group" "web-servers-backend-group" {
  name = "web-servers-backend-group"

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web-servers-target-group.id]
    load_balancing_config {
      panic_threshold = 50
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

#----------------- HTTP router -----------------
resource "yandex_alb_http_router" "web-servers-http-router" {
  name = "web-servers-http-router"
}

resource "yandex_alb_virtual_host" "web-servers-virtual-host" {
  name           = "web-servers-virtual-host"
  http_router_id = yandex_alb_http_router.web-servers-http-router.id
  route {
    name = "web-servers-virtual-host-path"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web-servers-backend-group.id
        timeout          = "3s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web-servers-balancer" {
  name               = "web-servers-balancer"
  network_id         = yandex_vpc_network.network_terraform.id
  security_group_ids = [yandex_vpc_security_group.public-alb.id, yandex_vpc_security_group.only_internal.id] 

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "${yandex_vpc_subnet.subnet_4.id}"
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web-servers-http-router.id
      }
    }
  }
}


#
# ---------------------------------------------------------------------------
#       Создаем файл hosts.txt для Ansible
# ---------------------------------------------------------------------------
#

resource "local_file" "host_file_4_ansible" {
    content  = join("\n",
               [
                "[zabbix_agent]",
                "vm-1        ansible_host=${yandex_compute_instance.vm-1.fqdn}",
                "vm-2        ansible_host=${yandex_compute_instance.vm-2.fqdn}",
                "",
                "[zabbix_server]",
                "vm-zabbix   ansible_host=${yandex_compute_instance.vm-zabbix.fqdn}",
                "",
                "[elk]",
                "es-server  ansible_host=${yandex_compute_instance.es.fqdn}",
                "kibana-server  ansible_host=${yandex_compute_instance.kibana.fqdn}",
                "",
                "[all_servers:children]",
                "zabbix_agent",
                "zabbix_server",
                "elk",
                "",
                "[all_servers:vars]",
                "ansible_user=user",
                "ansible_ssh_private_key_file=${var.private_key_path}",
                "ansible_ssh_common_args='-o ProxyCommand=\"ssh -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} -o StrictHostKeyChecking=accept-new -o IdentityFile=${var.private_key_path} -o Port=22 -W %h:%p\"'",
                "",
               ]
              )
    filename = "hosts.txt"
}

#
# ---------------------------------------------------------------------------
#                 Работаем с Ansible
# ---------------------------------------------------------------------------
#

resource "time_sleep" "wait_seconds" {
  create_duration = "3s"
  depends_on = [yandex_alb_load_balancer.web-servers-balancer]
}

#-----------------Ставим Zabbix-server используя Жестокий Hard Coding-----------------

resource "null_resource" "update_4_zabbix_server" {
  provisioner "local-exec" {
    command = "ansible zabbix_server -m shell -a 'sudo apt update -y | sudo apt upgrade -y' -b"
  }
  depends_on = [time_sleep.wait_seconds]
}

resource "null_resource" "apache2_install" {
  provisioner "local-exec" {
    command = "ansible zabbix_server -m apt -a 'name=apache2 state=latest' -b"
  }
  depends_on = [null_resource.update_4_zabbix_server]
}

resource "null_resource" "postgresql_install" {
  provisioner "local-exec" {
    command = "ansible zabbix_server -m apt -a 'name=postgresql state=latest' -b"
  }
  depends_on = [null_resource.apache2_install]
}

resource "null_resource" "step_1_zabbix" {
  provisioner "local-exec" {
    command = "ansible zabbix_server -m copy -a 'src=script_4_zabbix_server.sh dest=./ mode=777' -b"
  }
  depends_on = [null_resource.postgresql_install]
}

resource "null_resource" "step_3_zabbix" {
  provisioner "local-exec" {
    command = "ansible zabbix_server -m shell -a 'sudo bash script_4_zabbix_server.sh' -b > ./logs/mylog_zabbix_server.log"
  }
  depends_on = [null_resource.step_1_zabbix]
}

#-----------------Ставим Zabbix-agent используя Жестокий Hard Coding------------------------------------------------

resource "null_resource" "step_0_zabbix_agent" {
  provisioner "local-exec" {
    command = "ansible zabbix_agent -m copy -a 'src=script_4_zabbix_agent.sh dest=./ mode=777' -b"
  }
  depends_on = [time_sleep.wait_seconds]
}

resource "null_resource" "step_1_zabbix_agent" {
  provisioner "local-exec" {
    command = "ansible zabbix_agent -m shell -a 'sudo bash script_4_zabbix_agent.sh ${yandex_compute_instance.vm-zabbix.network_interface.0.ip_address}' -b > ./logs/mylog_zabbix_agent.log"
  }
  depends_on = [null_resource.step_0_zabbix_agent]
}

#-----------------Ставим Elasticsearch используя Жестокий Hard Coding-----------------

resource "null_resource" "step_0_es" {
  provisioner "local-exec" {
    command = "ansible es-server -m copy -a 'src=./elk/es/ dest=./ mode=777' -b"
  }
  depends_on = [time_sleep.wait_seconds]
}

resource "null_resource" "step_1_es" {
  provisioner "local-exec" {
    command = "ansible es-server -m copy -a 'src=elasticsearch.sh dest=./ mode=777' -b"
  }
  depends_on = [null_resource.step_0_es]
}

resource "null_resource" "step_2_es" {
  provisioner "local-exec" {
    command = "ansible es-server -m shell -a 'sudo bash elasticsearch.sh' -b > ./logs/mylog_elasticsearch.log"
  }
  depends_on = [null_resource.step_1_es]
}

#-----------------Ставим Kibana используя Жестокий Hard Coding-----------------

resource "null_resource" "step_0_kibana" {
  provisioner "local-exec" {
    command = "ansible kibana-server -m copy -a 'src=./elk/kibana/ dest=./ mode=777' -b"
  }
  depends_on = [time_sleep.wait_seconds]
}

resource "null_resource" "step_1_kibana" {
  provisioner "local-exec" {
    command = "ansible kibana-server -m copy -a 'src=kibana.sh dest=./ mode=777' -b"
  }
  depends_on = [null_resource.step_0_kibana]
}

resource "null_resource" "step_2_kibana" {
  provisioner "local-exec" {
    command = "ansible kibana-server -m shell -a 'sudo bash kibana.sh ${yandex_compute_instance.es.network_interface.0.ip_address}' -b > ./logs/mylog_kibana.log"
  }
  depends_on = [null_resource.step_1_kibana]
}

#-----------------Ставим Filebeat на wm-1 и wm-2 используя Жестокий Hard Coding-----------------

resource "null_resource" "step_0_filebeat" {
  provisioner "local-exec" {
    command = "ansible zabbix_agent -m copy -a 'src=./elk/filebeat/ dest=./ mode=777' -b"
  }
  depends_on = [null_resource.step_1_zabbix_agent]
}

resource "null_resource" "step_1_filebeat" {
  provisioner "local-exec" {
    command = "ansible zabbix_agent -m copy -a 'src=filebeat.sh dest=./ mode=777' -b"
  }
  depends_on = [null_resource.step_0_filebeat]
}

resource "null_resource" "step_2_filebeat" {
  provisioner "local-exec" {
    command = "ansible vm-1 -m shell -a 'sudo bash filebeat.sh ${yandex_compute_instance.es.network_interface.0.ip_address} ${yandex_compute_instance.vm-1.network_interface.0.ip_address}' -b > ./logs/mylog_filebeat_vm1.log"
  }
  depends_on = [null_resource.step_1_filebeat]
}

resource "null_resource" "step_3_filebeat" {
  provisioner "local-exec" {
    command = "ansible vm-2 -m shell -a 'sudo bash filebeat.sh ${yandex_compute_instance.es.network_interface.0.ip_address} ${yandex_compute_instance.vm-2.network_interface.0.ip_address}' -b > ./logs/mylog_filebeat_vm2.log"
  }
  depends_on = [null_resource.step_1_filebeat]
}

#
# ---------------------------------------------------------------------------
#                 Резервное копирование (snapshots)
# ---------------------------------------------------------------------------
#

resource "yandex_compute_snapshot_schedule" "default" {
  name = "default"

  schedule_policy {
    expression = "0 18 * * *"
  }

  snapshot_count = 7

  disk_ids = [yandex_compute_instance.vm-1.boot_disk[0].disk_id,
              yandex_compute_instance.vm-2.boot_disk[0].disk_id,
              yandex_compute_instance.vm-zabbix.boot_disk[0].disk_id,
              yandex_compute_instance.es.boot_disk[0].disk_id,
              yandex_compute_instance.kibana.boot_disk[0].disk_id,
              yandex_compute_instance.bastion.boot_disk[0].disk_id]
              
}

#
# ---------------------------------------------------------------------------
#       Аутпуты
# ---------------------------------------------------------------------------
#

output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}
output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "internal_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.ip_address
}
output "external_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}

output "internal_ip_address_vm-zabbix" {
  value = yandex_compute_instance.vm-zabbix.network_interface.0.ip_address
}
output "external_ip_address_vm-zabbix" {
  value = yandex_compute_instance.vm-zabbix.network_interface.0.nat_ip_address
}

output "internal_ip_address_elasticsearch" {
  value = yandex_compute_instance.es.network_interface.0.ip_address
}
output "external_ip_address_elasticsearch" {
  value = yandex_compute_instance.es.network_interface.0.nat_ip_address
}

output "internal_ip_address_kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.ip_address
}
output "external_ip_address_kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}
output "internal_ip_address_bastion" {
  value = yandex_compute_instance.bastion.network_interface.0.ip_address
}
output "external_ip_address_bastion" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}
output "external_ip_address_alb_load_balancer" {
  value = yandex_alb_load_balancer.web-servers-balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}
