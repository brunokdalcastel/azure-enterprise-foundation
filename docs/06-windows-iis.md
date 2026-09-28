# Parte 4 — Windows Server e IIS

Concluída em 23/09/2026. VM criada, testada e removida junto com disco/IP/componentes temporários. Resultados e limites dos testes em [evidências](07-evidencias-windows-iis.md). As seções de proposta abaixo registram decisões anteriores; as evidências descrevem o resultado final.

## Alteração de SKU fundamentada
Revisão em 23/09/2026: a configuração foi ajustada para Windows Server 2019 e uma família de VM candidata aos benefícios da oferta gratuita. A tentativa anterior com D2as v6 foi interrompida, sem recursos de workload criados. O plano salvo anterior foi descartado. Microsoft.Compute foi registrado, sem upgrade. B1s retorna NotAvailableForSubscription em Brazil South; B2ats_v2 é o candidato atual, ainda sujeito a disponibilidade, quota, compatibilidade e benefício da assinatura. workload_enabled e admin_access_enabled permanecem false.

Atualizada Policy de SKU para usar a variável vm_size, alinhada à VM. Não há liberação genérica de todos os tamanhos.

## Componentes
Migração para North Central US autorizada em 23/09/2026. B2ats_v2 nessa região retornou sem restrições e com quota regional/família 0/4 vCPUs; a imagem fixa foi confirmada. Isso não reserva capacidade física. Backend segue em Brazil South. Grupos, rede e workload usam sufixo ncu; bootstrap mantém brs. Rede e regras são reconstruídas juntas via replace_triggered_by.

- Proposta: Windows Server 2019 Core Gen2, versão fixa 17763.9245.260906, imagem smalldisk, candidato Standard_B2ats_v2, SCSI. Validar suporte do SKU a Secure Boot/vTPM antes de aplicar. Core administra por PowerShell, sem desktop completo.
- Disco de SO Standard SSD LRS 32 GiB proposto, NIC com IP privado 10.10.20.10 e IP Standard para saída explícita. Confirmar tamanho mínimo da imagem no preflight.
- IIS instalado por Custom Script Extension, script versionado e idempotente. Página interna sem dados reais.
- Windows Firewall: HTTP somente de 10.10.40.10; RDP TCP somente dos IPs administrativos; NLA obrigatória. NSG não publica HTTP na Internet.
- Desligamento automático às 22h, horário de São Paulo, como proteção adicional. Não substitui desalocar ao terminar os testes.
- Senha local gerada criptograficamente em arquivo tfvars ignorado pelo Git. Terraform armazena senha no estado remoto; `sensitive` não a remove do estado. Não imprimir o arquivo ou compartilhar state/plans.

## Custos de referência
A cotação anterior D2as/E10 foi substituída e não deve orientar o novo apply. Recalcular compute, disco E4 e IP na região escolhida. A documentação lista B1s e B2ats_v2 na oferta gratuita com limites de horas; a elegibilidade do tamanho não garante saldo do benefício nem disponibilidade. Disco/IP e operações podem consumir créditos, inclusive com VM desalocada. Sem upgrade, reserva ou Spot.

## Rotina
- workload_enabled controla existência do conjunto: false remove VM/NIC/disco/IP/extensão/shutdown via Terraform, após revisar plano.
- admin_access_enabled controla abertura administrativa na subnet application; false entre sessões.
- Iniciar VM via Azure CLI não exige recriação Terraform. Antes de abrir RDP, conferir IP permitido no NSG e Windows Firewall. IP de trabalho ainda não informado.
- Ao mudar admin_ipv4s, atualizar bootstrap/foundation; aplicar extensão atualiza o Windows Firewall quando VM estiver ligada. Não presumir que atualizar apenas NSG atualiza firewall do Windows.
- Ao terminar os testes, fechar RDP no código, registrar as evidências e remover o workload, incluindo disco e IP público.

## Validação planejada
Estado Azure, extensão, HTTP local 200, conteúdo da página, Firewall/NLA, HTTPS de saída, RDP TCP do executor e HTTP público bloqueado. Não confundir porta RDP acessível com login interativo concluído. Teste entre subnets com segunda VM pertence à Parte 5.

## Fontes
[Serviços da conta gratuita](https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/create-free-services), [custo de VM](https://learn.microsoft.com/en-us/azure/virtual-machines/cost-optimization-plan-to-manage-costs), [preflight local](05-preflight-windows.md).

## Resultado da migração em 23/09/2026
Foundation migrada para North Central US com grupos e rede ncu. Validação Azure PASS; plano final sem diferenças. East US bloqueada por Policy e North Central US aceita. Workload ainda vazio, RDP fechado. Backend preservado em Brazil South. Incidente de leituras contraditórias após reutilizar IDs resolvido reconstruindo com IDs novos. Network Watcher automático nas duas regiões deve ser tratado no teardown.
