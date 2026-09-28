# Custos e preflight

## Regras
Executar somente em assinatura e escopo autorizados. Neste laboratório, Free Trial e spending limit On foram verificados, sem upgrade. Não remover essa proteção. Saldo/validade são informações locais e não são publicados; cotação não equivale a consumo real nem a garantia de benefício gratuito.

## Ciclo econômico
Preparar código e teste antes de criar. Validar região, SKU, imagem, quota, preço, assinatura e IP do backend. Criar apenas temporários necessários, guardar evidências e destruir VM/disco/IP/alertas após cada bloco. Desalocar sozinho não elimina todos os custos. Backend Storage permanece até teardown final e também pode consumir créditos.

## Referências atuais
North Central US, consulta24/09/2026, BRL: Windows B2ats_v2 R$0,0962/h fora do benefício; IPStandard R$0,0259/h; disco E4LRS32GiB R$12,4082/mês +R$0,0103/10mil operações. Um conjunto ~R$0,1391/h usando730h para ratear disco, antes de tráfego/operações/diagnóstico. Partes4/5 documentam implantação, testes e remoção. Cotação do backend BrazilSouth em docs/03-preparacao-bootstrap.md.

Azure Monitor: conferir franquias e uso compartilhado da assinatura, séries de métricas e notificações antes de habilitar. Não usar Log Analytics/VM Insights/agentes pagos neste desenho. A Parte6 registra cotação e resultados de alertas.

## Verificações por sessão
- Modalidade, spending limit, crédito e validade.
- Permissões do executor e escopo das identidades temporárias.
- Disponibilidade, quota e compatibilidade de SKU/imagem/região.
- Preços e duração prevista, incluindo custos quando a VM estiver parada.
- Backend acessível pelo IP administrativo autorizado; senha/e-mail em arquivos ignorados.
- Plano revisado e roteiro de testes/limpeza antes de apply.
- Inventário final: discos, IPs, alertas, snapshots e identidades, incluindo itens fora do state.

Budget avisa; não bloqueia consumo. Configurações financeiras e contatos pessoais ficam em arquivos locais fora do repositório. Não criar ou excluir Budget preexistente sem autorização. Custos medidos têm atraso; não declarar consumo zero apenas por ausência de cobrança imediata.

[API de preços](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices), [Calculadora Azure](https://azure.microsoft.com/en-us/pricing/calculator/), [Budget](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets).
