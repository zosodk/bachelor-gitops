# /terraform/inventory.tf

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    # Jeg sender variablen 'k8s_nodes' direkte ind i templaten
    # Da jeg bruger statiske IP'er defineret i variables.tf, er det sikrest at bruge dem som kilde
    nodes = var.k8s_nodes
  })
  filename = "../ansible/inventory.yaml"
  file_permission = "0644"