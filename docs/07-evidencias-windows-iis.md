# Parte 4 — evidências Windows/IIS

Teste realizado em 23/09/2026, North Central US. Evidências sanitizadas: sem senhas, IPs públicos, identificadores de assinatura ou conteúdo do estado.

## Implantação verificada
- Standard_B2ats_v2, Windows Server 2019 Core Gen2, imagem 17763.9245.260906.
- Disco Standard SSD LRS de 32 GiB; imagem com mínimo de 30 GiB.
- Trusted Launch com Secure Boot e vTPM habilitados.
- IIS provisionado por extensão Terraform; desligamento automático configurado para 22h de São Paulo.
- Free Trial e spending limit On reconfirmados. Nenhum upgrade.

## Resultados
| Verificação | Resultado |
|---|---|
| Serviço IIS | Running |
| GET local /index.html | HTTP 200, conteúdo Contoso Brasil |
| Windows Firewall HTTP | Restrito exclusivamente a 10.10.40.10 |
| Regra RDP e NLA | Habilitadas durante o teste |
| Saída HTTPS para login.microsoftonline.com:443 | Sucesso |
| Licenciamento Windows | LicenseStatus 1, ativado |
| TCP RDP a partir do executor autorizado | Acessível |
| TCP HTTP pelo IP público | Sem conexão |
| Network Watcher IP flow: HTTP de 10.10.40.10 | Allow, allow-test-http-in |
| Network Watcher IP flow: HTTP de 10.10.40.11 | Deny, deny-lateral-in |

Run Command executou scripts/Test-WindowsGuest.ps1: todas as verificações booleanas true, stderr vazio. O teste TCP RDP não comprova login interativo. IP flow verifica regras efetivas, não substitui tráfego real entre VMs; esse teste pertence à Parte 5.

## Custos e ciclo de vida
Referência da Retail Prices API em BRL: VM Windows R$ 0,0962/h fora do benefício; IP Standard R$ 0,0259/h; disco E4 LRS R$ 12,4082/mês, mais R$ 0,0103/10 mil operações. Rateio do disco em 730h resulta em cerca de R$ 0,1391/h para o conjunto, antes de operações, tráfego e diagnóstico. Valores são cotação, não gasto realizado; saldo do benefício de horas não confirmado.

Após os testes, workload_enabled e admin_access_enabled retornaram a false. Terraform removeu os seis recursos temporários. Inventário do grupo workload e lista de IPs públicos vazios; disco de SO removido junto com a VM. Backend permanece necessário para a infraestrutura ativa e será removido por último no encerramento.

## Incidente tratado
Uma conexão ao Storage foi interrompida após a criação da VM. O estado remoto foi conferido: VM, NIC, IP e regra estavam registrados. Um plano novo adicionou somente extensão e desligamento automático, sem recriar a VM.

## Verificação após limpeza
Test-Foundation.ps1 PASS: governança/rede preservadas e RDP fechado. Inventário global de discos e IPs públicos vazio. Plano Terraform final detailed-exitcode 0, No changes. Spending limit On.
