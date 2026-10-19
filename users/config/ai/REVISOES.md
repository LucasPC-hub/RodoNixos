# Revisões paralelas

Esse é o padrão que eu uso antes de considerar uma entrega pronta. Ele fica aqui pra qualquer IA do PC conseguir usar, em qualquer sessão e em qualquer projeto.

## O problema que isso resolve

Quem escreveu o código é a pior pessoa pra revisar o código. Você revisa o que *pretendia* fazer, não o que está no arquivo. As decisões parecem óbvias porque você lembra do raciocínio, e os buracos ficam invisíveis porque você nunca pensou neles em primeiro lugar.

Rodar os testes não resolve. Teste prova que o que você imaginou funciona. Não prova que você imaginou tudo.

A saída é mandar outras pessoas olharem, com o olhar já direcionado. Vários revisores, cada um com uma pergunta diferente na cabeça, rodando ao mesmo tempo e sem conversar entre si.

## Por que separar, e não fazer uma revisão só

Uma revisão genérica ("revisa esse código aí") volta com uma lista morna de coisas óbvias. Revisor sem pergunta específica acha o que é fácil de achar: nome de variável, função grande, comentário faltando.

Os bugs que importam moram em lugares bem diferentes, e cada lugar exige um modo de pensar:

- Pra achar falha de segurança você pensa como atacante, de fora pra dentro.
- Pra achar violação de padrão você pensa como mantenedor, lendo o código daqui a seis meses.
- Pra achar quebra em runtime você pensa como o processo rodando, de dentro pra fora.

Ninguém faz tudo isso bem ao mesmo tempo. Separar é o que faz cada um descer fundo.

Numa rodada normal, três revisões é o limite prático. Com cinco ou seis, os achados começam a se repetir e você gasta mais tempo triando duplicata do que corrigindo. Rodar todas faz sentido quando a entrega é grande ou quando eu pedir, e aí o resumo final precisa juntar o que se repetiu.

## O que o revisor faz e o que ele não faz

Revisão **só analisa e registra**. Ela não corrige nada.

- Não edita arquivo do repo, não commita, não roda formatter nem `--fix`, não troca a branch de ninguém.
- Pode ler código, rodar `git log` e `git diff`, consultar banco ou API em modo leitura, e rodar teste ou typecheck, desde que isso não mude nenhum arquivo do repo.
- O resultado vira um relatório escrito. Decidir o que corrigir é de quem pediu a revisão, depois de ler.

Se três agentes editarem o mesmo arquivo ao mesmo tempo, você perde trabalho e não sabe qual mudança veio de quem. Por isso a regra não tem exceção.

## As revisões

As três primeiras são o padrão. As outras entram no lugar de uma delas, ou somam, quando a entrega pede.

### 1. Segurança

**A pergunta:** como alguém mal-intencionado quebra isso?

Esse revisor pensa como atacante. Ele não quer saber se o código está bonito, quer saber o que acontece quando a entrada é hostil.

O que ele procura, na prática:

- dado que vem do cliente e é usado sem conferir (mimetype, nome de arquivo, id na URL)
- escopo furado: dá pra ler ou escrever o recurso de outra pessoa?
- informação vazando na resposta ou na mensagem de erro
- credencial, token, senha ou documento aparecendo em log
- limite que dá pra furar com concorrência
- recurso sem teto: upload sem tamanho máximo, endpoint caro sem rate limit

Esse é o único que vale usar um agente especializado, se você tiver um. A diferença aparece.

### 2. Padrões e qualidade

**A pergunta:** daqui a seis meses, alguém entende e consegue mexer nisso?

Esse revisor lê como mantenedor. Ele compara o código novo com as convenções que o projeto já tem, e procura o que vai apodrecer.

O que ele procura:

- a entrega seguiu os padrões escritos do projeto, ou inventou um segundo jeito de fazer a mesma coisa?
- código intuitivo: funções pequenas que chamam outras, complexidade quebrada em passos com nome
- função fazendo coisa demais, assinatura com parâmetros repetidos e trocáveis
- comentário que repete o código em vez de explicar a decisão
- regra de negócio copiada em três lugares
- **teste tautológico**: aquele que passa com qualquer implementação, tipo mockar o retorno e conferir que o retorno é o que foi mockado
- documentação que não bate com o que o código faz de verdade

Esse último item parece pequeno e não é. Documentação errada é pior que documentação ausente, porque alguém vai confiar nela.

### 3. Runtime e impacto

**A pergunta:** isso sobe? E o que já existia continua funcionando?

Esse revisor pensa no processo rodando. É o que pega o que compila e passa nos testes, mas quebra no primeiro deploy.

O que ele procura:

- injeção de dependência que não resolve: o módulo declara tudo que o construtor pede?
- pacote usado mas não declarado no `package.json`, funcionando por acaso
- interface que cresceu e deixou outro implementador pra trás
- efeito colateral em quem você não tocou: outro fluxo escreve na mesma coluna? outro app importa esse arquivo?
- comportamento sob falha: o que acontece se o serviço externo não responder?
- contrato que mudou e tem consumidor do outro lado

É o revisor que mais acha coisa que os testes não pegam, porque testes rodam com tudo mockado e no deploy nada é mockado.

### 4. Completude e produto

**A pergunta:** o que foi combinado está aqui, e uma pessoa real consegue usar?

Esse revisor compara a entrega com o que foi prometido (task, spec, plano, casos de uso) e percorre o fluxo do jeito que o usuário vai percorrer, não do jeito que o teste percorre.

O que ele procura:

- item da task ou caso de uso que foi prometido e não existe
- coisa que entrou de carona: existe no código, mas ninguém pediu e não está documentada
- fluxo que passa no teste e que ninguém consegue completar na vida real (ditar um UUID por telefone)
- caminho triste esquecido: o que a pessoa vê quando dá erro, quando a lista vem vazia, quando ela volta pra tela
- estado que vaza entre usos: tela que mostra o dado da pessoa anterior
- README, CHANGELOG ou doc descrevendo um comportamento diferente do atual

É o revisor que pega o erro mais caro: entrega tecnicamente certa que não resolve o problema.

### 5. PR e higiene

**A pergunta:** esse PR está pronto pra outra pessoa revisar e mergear?

Esse revisor olha o PR como pacote, não o código linha a linha.

O que ele procura:

- a branch está em dia com a base? vai dar conflito, e onde?
- conflito já resolvido que apagou trabalho dos outros (CHANGELOG, migration, lockfile)
- arquivo alterado sem necessidade: só formatação, import reordenado, mudança de outro assunto
- comentário lixo de IA: narração do óbvio, TODO que ninguém vai fazer, log de debug esquecido
- script, rascunho ou arquivo de teste manual esquecido no repo
- mensagem de commit e CHANGELOG batendo com o que mudou de fato

É barata e rápida. Vale rodar antes de abrir qualquer PR, mesmo quando as outras não valem.

### 6. Dados e migrations

**A pergunta:** o que acontece com os dados que já estão no banco?

Esse revisor pensa no banco de produção: volume real e dado sujo acumulado em anos.

O que ele procura:

- migration que trava tabela grande: índice criado sem `CONCURRENTLY`, `ALTER` que reescreve a tabela inteira
- ordem obrigatória: o código novo sobe antes ou depois da coluna existir? tem migration que depende de outra?
- constraint nova (`NOT NULL`, `UNIQUE`, FK) que o dado antigo já viola
- volta atrás: tem rollback, ou pelo menos um plano escrito?
- backfill: quem preenche os registros antigos, e em quanto tempo
- query nova sem índice, N+1, listagem sem paginação
- duas escritas que precisam andar juntas e estão fora da mesma transação

Só vale quando a entrega toca schema, query pesada ou escrita em lote. Fora disso, pula.

### 7. Operação e observabilidade

**A pergunta:** quando isso der problema às três da manhã, dá pra descobrir o que aconteceu?

Esse revisor pensa em quem vai estar de plantão sem ter escrito o código.

O que ele procura:

- o fluxo novo aparece no log e no trace? dá pra seguir um pedido de ponta a ponta?
- erro logado com contexto suficiente (qual motorista, qual viagem) e sem dado sensível
- log demais: loop logando item por item, payload inteiro no log
- falha silenciosa: catch que engole o erro, job que morre sem avisar, retry infinito
- configuração nova: a variável de ambiente existe em todos os ambientes? o valor padrão é seguro?
- dá pra desligar ou reverter sem fazer outro deploy?

Vale pra job agendado, fila, integração externa e qualquer coisa que roda sem ninguém olhando.

## Como escolher

| A entrega... | Rode |
|---|---|
| mexe em autenticação, permissão ou escopo | segurança + runtime + completude |
| cria tela ou fluxo novo pro usuário | completude + padrões + runtime |
| mexe em schema ou query pesada | dados + runtime + padrões |
| é integração externa, job ou fila | operação + runtime + segurança |
| é segunda rodada em cima de correções | as mesmas da primeira, com a lista do que foi corrigido |
| vai virar PR | PR e higiene, além das outras |

Se eu pedir "todas", rodam as sete. Se eu pedir só algumas, rodam só essas.

## Como despachar

As revisões escolhidas rodam **ao mesmo tempo**, em paralelo. Não é pipeline. Uma não depende da outra e elas não devem conversar.

Contexto compartilhado, igual pra todas:

- qual é o objetivo da entrega, em duas frases
- lista exata dos arquivos que mudaram, incluindo os não rastreados pelo git
- o contrato: quais rotas, quais regras, o que é invariante
- onde estão os padrões escritos do projeto
- **o que foi corrigido numa rodada anterior, se houver**

Esse último ponto é o mais importante numa segunda rodada. Correção de bug é código novo que ninguém revisou, e correção malfeita é pior que o bug original. Diga explicitamente: "essas 9 coisas foram corrigidas, é nelas que o risco mora agora".

Duas regras que eu sempre coloco, além de "revisor não edita":

**Achado sem código citado não existe.** Exija arquivo, linha e o trecho. Isso corta a revisão genérica que fala bonito e não aponta nada.

**Tem que dizer o que está bom.** Senão o revisor inventa problema pra parecer útil. "A correção 2 ficou boa, aqui está o porquê" é informação tão valiosa quanto um achado.

### Tempo

Cada revisão deve levar uns 15 minutos. Pra isso:

- O revisor não roda a suíte inteira de testes nem o typecheck do monorepo. Isso leva muito tempo e não muda a revisão. Ele lê o código e, no máximo, roda um teste específico.
- Quem despacha acompanha. Se um revisor ficar uns 20 minutos sem nenhuma atividade nova, ele travou: encerra e faz aquela revisão por conta própria. Não adianta disparar de novo e esperar, porque costuma travar outra vez.

## Onde registrar

Cada rodada fica salva fora do repo, pra não sujar o PR:

```
~/develop/revisoes/<repo>/<branch com / trocada por ->/<AAAA-MM-DD>/
  1-seguranca.md
  2-padroes.md
  ...
  resumo.md
```

Cada revisão tem seu arquivo. O `resumo.md` junta tudo: o que corrigir primeiro, o que se repetiu entre revisões e o que ficou bom. Quem salva os arquivos é quem despachou, porque o agente revisor geralmente não tem permissão de escrita. Ele devolve o relatório como texto e quem despachou grava.

## Como escrever o relatório

Quem lê é gente com pressa. O relatório tem que dar pra entender numa leitura só.

- Escreva simples e didático, como quem explica pra uma colega. Pode ser informal.
- Tópicos podem, mas dentro deles vai frase de verdade, com sujeito, verbo e conectivo ("porque", "então", "mas", "e aí"). Nada de frase telegráfica que obriga o leitor a adivinhar a ligação entre as ideias.
- Sem travessão (— ou –). Use vírgula, ponto, dois-pontos ou parênteses.
- Sem lenga-lenga: nada de introdução, de "é importante notar que", de resumo do resumo, de elogio genérico.
- Termo técnico pode, desde que venha junto o efeito prático. Em vez de "race condition no upsert", escreva "se dois pedidos chegarem juntos, o segundo apaga o que o primeiro gravou".
- Cada achado diz o que acontece na prática, pra quem usa ou pra quem opera.

Formato de cada achado:

```
### título curto do problema

**Onde:** `caminho/arquivo.ts:42`
**Trecho:** o pedaço de código que mostra o problema
**O que acontece:** uma a três frases simples
**Sugestão:** o que mudar
**Prioridade:** crítico, importante ou cosmético
```

No fim de cada relatório vem uma seção **O que está bom**, com o porquê.

## O que fazer com o resultado

Isso é com quem pediu a revisão, depois de ler o relatório. Nem todo achado merece correção. A triagem importa tanto quanto a revisão.

**Corrija na hora:** qualquer coisa de segurança, qualquer coisa que quebra no deploy, e qualquer afirmação falsa em documentação. Essa última é traiçoeira: se o CHANGELOG diz que existe uma proteção que não existe, você acabou de criar um ponto cego pro time inteiro.

**Avalie com calma:** sugestão de refatoração e extração de função. Às vezes o revisor está certo, às vezes ele está pedindo abstração que não paga o preço.

**Recuse com motivo escrito:** quando o revisor não tem o contexto que você tem. Mas escreva o motivo no código ou no changelog, porque o próximo revisor vai levantar a mesma coisa.

**Quando o revisor estiver errado, confira antes de descartar.** Na minha última rodada, dois achados que eu ia descartar estavam certos, e eram sobre afirmações *minhas* que eram falsas. Eu tinha escrito que um app não tinha Redis, e tinha. Tinha escrito que havia limite na borda, e não havia.

## O que esse padrão já pegou

Pra dar a dimensão do que aparece, da última vez:

- um fluxo de ativação que **nenhum usuário real conseguiria completar**, porque exigia que alguém ditasse um UUID de 36 caracteres por telefone
- upload que aceitava qualquer binário declarado como imagem, indo parar num cadastro que a equipe interna também enxerga
- quatro releases apagadas do CHANGELOG por uma resolução de conflito malfeita minha, incluindo uma ordem obrigatória de migration
- duas justificativas minhas, escritas em comentário e changelog, que eram factualmente falsas
- código de uma pessoa vazando pra tela de outra, por componente que fica montado entre aberturas

Nenhum desses apareceria em teste. Os testes estavam todos verdes.

## Quando vale e quando não vale

**Vale** quando a entrega mexe em autenticação, permissão ou escopo de acesso; quando cria superfície nova consumida por alguém de fora; quando toca dado compartilhado entre times; ou quando é a segunda rodada em cima de correções.

**Não vale** pra mudança de uma linha, ajuste de texto, ou coisa que você vai jogar fora amanhã. O custo de contexto não paga.

**Sinal de que está valendo:** cada revisão volta com achados diferentes das outras. Se todas voltarem falando a mesma coisa, o recorte das perguntas está ruim e dá pra usar menos.
