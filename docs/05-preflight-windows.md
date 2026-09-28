# Conferência antes da Parte 4 — Windows/IIS

Consulta em 2026-09-22, somente leitura; nenhuma VM criada.

## Resultado confirmado
- Assinatura Enabled, FreeTrial_2014-09-01, spendingLimit On; sem alteração de cobrança.
- Standard_B2s_v2 em Brazil South consta no catálogo, mas retorna restrição Location e Zone com NotAvailableForSubscription. Não considerar SKU liberada nem prometer deploy.
- Microsoft.Compute está NotRegistered. Consultas de usage pela CLI e REST retornaram listas vazias; quota não está validada e lista vazia NÃO significa quota zero ou ilimitada.
- Imagem MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:20348.5622.260906 encontrada, x64, Hyper-V V2, SecurityType TrustedLaunchAndConfidentialVmSupported. Disco e implantação da combinação final ainda devem ser verificados.

## Cotação pública BRL — Brazil South
Azure Retail Prices API, Consumption, sem Spot/Low Priority, consultada em 22/09/2026:

| Componente | Medidor | Tarifa |
|---|---|---:|
| Windows Standard_B2s_v2 | Virtual Machines Bsv2 Series Windows / B2s v2 | R$ 0,7445/h |
| Disco Standard SSD 128 GiB | Standard SSD Managed Disks / E10 LRS Disk | R$ 92,6482/mês |
| Operações de disco | E10 LRS Disk Operations | R$ 0,0103 por 10 mil |
| IP público IPv4 Standard estático | IP Addresses / Standard IPv4 Static Public IP | R$ 0,0259/h |

A tarifa do SKU bloqueado é referência de planejamento, não uma configuração aprovada para implantação. Catálogo de preço não comprova disponibilidade.

Usando 730 horas/mês apenas como conversão estimativa: disco ~R$ 0,1269/h; conjunto ligado ~R$ 0,8973/h (compute + disco + IP), antes de operações/tráfego/backend e diferenças da oferta/impostos. Quatro horas com criação e exclusão no mesmo intervalo ~R$ 3,59 de base. Vinte horas ligadas, mantendo disco e IP por sete dias, ~R$ 40,56 de base. Desalocar para compute, mas disco/IP continuam enquanto existirem.

Não somar o medidor E10 LRS Disk Mount: ele corresponde a montagens adicionais de disco compartilhado, não ao disco de SO exclusivo deste lab. Não pressupor descontos/benefícios gratuitos sem confirmar elegibilidade.

## Antes da implementação
Encontrar SKU permitida e verificar quota após disponibilizar Microsoft.Compute, sem upgrade de assinatura. Se alterar SKU/região, revisar policy e cotação antes de apply. A consulta atual não registrou providers nem modificou recursos.

## Alternativas encontradas na mesma consulta
Filtro de catálogo: x64, 2 vCPUs, memória entre 4 e 8 GiB, sem restrição Location. Entre os resultados, Standard_D2as_v6 (restrições de zona presentes, candidato a implantação regional sem zona) e Standard_D2as_v7 (nenhuma restrição informada). Isso NÃO garante capacidade física no momento do deploy nem substitui quota.

Ambos cotados no catálogo BRL Windows Consumption normal a R$ 1,2305/h. Com E10 LRS rateado por 730h/mês e IP, base ~R$ 1,3833/h. Exemplo: 4 horas de existência ~R$ 5,53; 20 horas ligadas com disco/IP mantidos por sete dias ~R$ 50,28, antes de operações/tráfego/backend/impostos. Cotação, não cobrança realizada.

Recomendação preliminar: considerar D2as v6 regional sem zona, preservando Brazil South, após registrar Compute e conferir quota. Reavaliar v7 se a quota v6 não for suficiente. Nenhuma alteração da Policy (que ainda permite somente B2s v2) ou da arquitetura foi aplicada nesta conferência.

Fontes: [Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices), [Discos e cobrança](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-understand-billing), [Preços Managed Disks](https://azure.microsoft.com/en-us/pricing/details/managed-disks/).
