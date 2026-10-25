# Deadlock Outbreak — Development Status

**Atualizado:** 2026-10-25 (America/Fortaleza)
**Etapa 1:** 1.1–1.10 concluída conforme registro abaixo.
**Etapa 2:** 2.1–2.10 concluída conforme resultados abaixo.
**Etapa 3:** **CONCLUÍDA (100% no escopo técnico/build)** — subtarefas 3.1–3.10 e build Windows oficial validados no GitHub Actions; artifact disponível. Interface gráfica/mouse físico ainda não foi testado visualmente; essa limitação está registrada abaixo.

> Este documento é o registro atual de verificação do projeto. `docs/AMBIENTE.md` e `docs/FLUXO_WINDOWS.md` são notas históricas datadas de 2026-10-22/23; os dados de ambiente abaixo foram novamente verificados em 2026-10-25.

## Diagnóstico do ambiente

- **SO/arquitetura:** Debian GNU/Linux 12 (bookworm), kernel Linux 6.1.158+, x86_64; 2 vCPUs e aproximadamente 3,8 GiB de RAM.
- **Tela:** `DISPLAY` e `WAYLAND_DISPLAY` não definidos; este container é headless. Não há como abrir/verificar uma janela gráfica real ou testar visualmente F11 neste ambiente.
- **Godot no início:** nenhum executável Godot encontrado no `PATH` nem nos caminhos persistentes pesquisados. Não há instalação oficial disponível para uso normal/GUI.
- **Engine realmente usada para validação:** source tag `4.7.2-stable` compilada localmente com SCons; o binário executou `--version` e respondeu `4.7.2.stable.custom_build`. Foi construído para Linux x86_64, com backends de desktop desativados; serve para as verificações headless desta etapa, não é o editor Windows do usuário.
- **Metadados do projeto:** `project.godot` mantém o feature tag `4.4` da base existente (compatível com o Godot 4.4.1 descrito nos documentos anteriores); a abertura/execução foi testada no Godot 4.7.2 custom build. O projeto não foi atualizado de versão automaticamente.
- **Ferramentas auxiliares confirmadas:** Python 3, `g++`, `curl`, `tar` e Git. O SCons foi instalado em cache temporário para compilar o motor. `godot`, `godot4` e Blender não estavam no `PATH`. Blender não foi usado.
- **Recursos/rede:** havia espaço suficiente para a compilação. O source foi obtido por `codeload.github.com`; a instalação do motor oficial via pacote binário não foi necessária para validar o projeto.

## Resultado individual

**1.1 PASS** — Ambiente, arquitetura e limitação gráfica foram examinados. Não havia Godot instalado; compilei e executei uma build real de Godot 4.7.2. O comando real o binário temporário `.runtime-stage1/source/bin/godot.linuxbsd.editor.x86_64 --version` respondeu `4.7.2.stable.custom_build`. A execução normal com janela não pode ser demonstrada sem display e não é suportada por esta build headless.

**1.2 PASS** — O projeto existente foi preservado, sem criar outro. `godot --headless --editor --path <raiz> --quit` reconheceu o projeto, leu a cena e o script, e encerrou com código 0. O editor gráfico não está disponível neste container.

**1.3 PASS** — O projeto tem nome `Deadlock Outbreak`, main scene, renderer Compatibility, janela inicial windowed/redimensionável e ações de entrada registradas. O teste headless lê esses valores do próprio `ProjectSettings`. A janela gráfica não pôde ser aberta para inspeção visual.

**1.4 PASS** — A configuração e a leitura em runtime confirmam viewport **1280×720** e override de janela **1280×720**. A dimensão física de uma janela não foi verificada, pois não há display neste ambiente.

**1.5 PASS** — Estrutura compacta criada/verificada: `scenes/`, `scripts/`, `assets/{models,textures,materials,animations,audio,ui}/`, `systems/`, `player/`, `zombies/`, `weapons/`, `map/`, `multiplayer/`, `ui/`, `tests/` e `docs/`. As categorias futuras estão apenas como diretórios; não foram adicionados sistemas de gameplay.

**1.6 PASS** — Existe uma cena inicial válida, `scenes/main.tscn`. Ela contém apenas a raiz 3D e o script existente de controle de janela. Nenhuma cena de mapa, jogador ou inimigo foi criada.

**1.7 PASS** — `scenes/main.tscn` é a cena de entrada e usa `Node3D` como raiz apropriada para a base 3D. O teste carregou, instanciou e adicionou a cena ao `SceneTree`.

**1.8 PASS** — `application/run/main_scene` aponta para `res://scenes/main.tscn`. O projeto iniciou diretamente em modo headless (`--headless --path <raiz> --quit-after 2`) com código 0. A execução em janela e no Windows não pôde ser testada neste Linux sem display.

**1.9 PASS** — O teste customizado `tests/project_smoke_test.gd` terminou com código 0 e confirmou nome, cena, raiz Node3D, renderer, viewport/janela 1280×720, modo windowed, stretch e todas as dez ações com eventos vinculados. A segunda varredura do editor headless terminou sem erros ou warnings de projeto. A primeira varredura apontou que o GLB Inspector contém um subprojeto Godot de teste; foi adicionado `GLB-Inspector/.gdignore` para o projeto do jogo não importar essa ferramenta nem seus fixtures. Isso não altera o código/comportamento do Inspector.

**1.10 PASS** — Este arquivo registra versão, estrutura, configuração, sistemas existentes, comandos, resultados e limitações desta etapa.

## Configuração e estrutura resultantes

- Nome: `Deadlock Outbreak`.
- Main scene: `res://scenes/main.tscn`.
- Raiz da cena: `Node3D`; script existente: `res://scripts/core/window_controller.gd` (mantido).
- Renderização: Godot **GL Compatibility** (`gl_compatibility`), escolha adequada à compatibilidade ampla e à estética low-poly prevista.
- Viewport e janela inicial: **1280×720**, windowed, redimensionável; stretch permanece `disabled`, sem UI avançada.
- Entradas existentes: `move_forward`, `move_backward`, `move_left`, `move_right`, `interact`, `primary_action`, `secondary_action`, `reload`, `pause`, `toggle_fullscreen`. Só foram verificadas as configurações; não foram implementadas ações de gameplay.
- Sistemas de gameplay existentes: nenhum. A cena principal é uma base vazia intencional.

## Testes realmente executados

| Verificação | Comando/resultado |
|---|---|
| Versão real do motor | `godot --version` → `4.7.2.stable.custom_build` |
| Abertura/importação do projeto | `godot --headless --editor --path <raiz> --quit` → exit 0; varredura final sem erros/warnings do projeto |
| Inicialização da main scene | `godot --headless --path <raiz> --quit-after 2` → exit 0 |
| Configuração/cena/inputs em runtime | `godot --headless --path <raiz> --script res://tests/project_smoke_test.gd` → exit 0 e `DEADLOCK_STAGE1_RESULT` com `ok: true` |
| Referências | A varredura do editor carregou `scenes/main.tscn` e `scripts/core/window_controller.gd`; o smoke test confirmou a cena no `SceneTree` e não encontrou recursos ausentes |
| Janela gráfica/Windows | **Não testado:** ambiente Linux sem `DISPLAY`/Wayland; sem build Windows nem editor gráfico disponível |

O engine de validação foi compilado de source somente para esta verificação e sem backends gráficos do host. O processo de build emitiu avisos não fatais de `msgfmt` ausente (usou arquivos `.po`); isso não apareceu como erro/warning do projeto nos testes finais. A janela 1280×720 foi confirmada pela configuração/runtime do Godot, não por captura de uma janela física.

## Arquivos desta etapa

**Criados:**

- `docs/DEVELOPMENT_STATUS.md` — este registro.
- `tests/project_smoke_test.gd` — teste headless de configuração, cenas e input map.
- `scripts/core/window_controller.gd.uid` e `tests/project_smoke_test.gd.uid` — UIDs criados pelo editor Godot ao importar scripts.
- `.gitkeep` em `assets/models/`, `assets/textures/`, `assets/materials/`, `assets/animations/`, `assets/audio/`, `assets/ui/`, `systems/`, `player/`, `zombies/`, `weapons/`, `map/`, `multiplayer/`, `ui/` e `tests/` para manter a estrutura vazia no workspace.
- `GLB-Inspector/.gdignore` — impede o importador do jogo de varrer a ferramenta web e detectar o projeto Godot de smoke test aninhado.

**Modificados:**

- `project.godot` — nome exibido atualizado para `Deadlock Outbreak`; cena principal, renderer, janela e entradas existentes foram preservados.
- `scenes/main.tscn` — raiz alterada de `Node2D` para `Node3D`, sem remover o script de janela existente.

`GLB-Inspector` não recebeu mudanças funcionais. Nenhum arquivo de gameplay, mapa, player, zumbi, arma ou multiplayer foi criado. Nenhum arquivo foi staged, commitado ou enviado.

## Limitações e estado atual

1. O container não tem display: modo gráfico, fullscreen físico, resolução observada na tela e execução Windows continuam sem teste real.
2. A build 4.7.2 custom foi compilada para headless e não substitui a distribuição oficial Godot Standard para desenvolvimento visual. Para abrir o editor no Windows, use a instalação Standard GDScript indicada em `docs/FLUXO_WINDOWS.md` (Godot 4.4.1) ou uma versão Godot 4 compatível.
3. O binário e os intermediários de compilação são artefatos locais de validação, não foram adicionados ao projeto. O comando `godot` não fica instalado no `PATH` após a limpeza do cache de build desta execução.
4. Os documentos `docs/AMBIENTE.md` e `docs/FLUXO_WINDOWS.md` permanecem como notas históricas; este arquivo contém a situação atual da Etapa 1.

**Estado do jogo:** fundação técnica e main scene executáveis em headless; nenhum sistema de jogo implementado.

## Etapa 2 — progresso por subtarefa

**2.1 CONCLUÍDA** — Convenções de nomes definidas e documentadas em `docs/TECHNICAL_ARCHITECTURE.md`. Arquivos/script/cena atuais avaliados; nenhum renomeamento necessário. Verificação Python de nomes, funções e constantes: PASS.

**2.2 CONCLUÍDA** — `scripts/core/window_controller.gd` está em `scripts/core/`; os testes smoke/erro ficam em `tests/`. Não criei scripts vazios. Auditoria estática e validação GDScript real: PASS.

**2.3 CONCLUÍDA** — `scenes/main.tscn` continua única cena/ponto de entrada; documentei organização futura sem criar cenas vazias. Auditoria estática de nó-raiz, ID de recurso, caminho e `run/main_scene`: PASS.

**2.4 CONCLUÍDA** — Documentei a estrutura e convenções de modelos, texturas, materiais, animações, áudio, fontes, UI e recursos genéricos; acrescentei `assets/fonts/` e `assets/resources/`. A verificação confirmou apenas `.gitkeep`, sem recursos fictícios.

**2.5 CONCLUÍDA** — Documentadas chamadas diretas, sinais, grupos, Autoloads e RPC, com critérios de uso. Busca estática confirmou que hoje não há dependências entre sistemas nem infraestrutura global artificial; nenhuma implementação extra é necessária. PASS.

**2.6 CONCLUÍDA** — `project.godot` é a fonte única para janela, resolução, renderer e InputMap. `window_controller.gd` agora lê o tamanho configurado (viewport como fallback) em vez de duplicar 1280×720; smoke test cobre o valor. Auditoria estática: PASS.

**2.7 CONCLUÍDA** — Grafo atual é `project.godot → main.tscn → window_controller.gd`; teste depende dos alvos, não é carregado pelo runtime. Auditoria estática confirmou todos os destinos e zero ciclos. PASS.

**2.8 CONCLUÍDA** — `WindowController` verifica a action requerida; tamanho inválido gera warning e usa viewport, com fallback de emergência documentado. `tests/project_error_test.gd` confirmou mensagem para recurso ausente e fallback de override inválido. Godot 4.7.2, exit 0/`ok:true`; warning do override foi esperado e validado.

**2.9 CONCLUÍDA** — Auditoria de 7 referências `res://`: todos os alvos reais existem; o único caminho ausente é o fixture intencional do teste. Varredura real do editor headless completou sem erros/warnings de projeto.

**2.10 CONCLUÍDA** — Godot 4.7.2 executou scan do editor, inicialização da main scene, smoke test da Etapa 1 e teste de erro da Etapa 2; todos exit 0. Verificação estática final: nomenclatura, assets, referências e ciclos: PASS. Detalhes abaixo.

### Arquivos criados/alterados na Etapa 2

**Criados:** `docs/TECHNICAL_ARCHITECTURE.md`; `tests/project_error_test.gd`; `assets/fonts/.gitkeep`; `assets/resources/.gitkeep`. O editor Godot gerou `tests/project_error_test.gd.uid` ao importar o teste.

**Alterados:** `scripts/core/window_controller.gd` lê a resolução centralizada de `project.godot` e reporta action ausente/override inválido; `tests/project_smoke_test.gd` verifica o valor comum; este status documenta os resultados. Nenhum script, cena ou asset existente foi apagado ou renomeado.

### Validação final da Etapa 2

- Godot 4.7.2 source custom build: `--version` → `4.7.2.stable.custom_build`.
- `--headless --editor --path <raiz> --quit-after 600`: exit 0, scan/import completo, sem erros/warnings do projeto.
- `--headless --path <raiz> --quit-after 2`: exit 0, execução direta da main scene.
- `--headless --path <raiz> --script res://tests/project_smoke_test.gd`: exit 0, `DEADLOCK_STAGE1_RESULT ok:true`.
- `--headless --path <raiz> --script res://tests/project_error_test.gd`: exit 0, `DEADLOCK_ERROR_TEST_RESULT ok:true`; warning sobre override inválido é intencional no teste e confirma o fallback 1280×720.
- Auditoria estática: nomes, pastas de recursos, 7 edges `res://` e dependências: PASS; zero ciclos e um path ausente intencional no teste.
- Tentativas de encerrar o editor cedo (`--headless --editor --quit`, singleton nulo em `EditorNode::is_cmdline_mode`; e `--quit-after 5`, warning `Scan thread aborted`) interromperam a inicialização. Foram substituídas por `--quit-after 600`, que permite concluir a varredura e sai limpo. Não eram erros de cena/script do projeto.

**Avisos/limitações do build:** o compilador emitiu warnings não fatais de código do próprio engine (ex.: variável não usada em OpenXR). O binário foi compilado somente para validação headless, não é um engine Windows/GUI; source, SCons e binário temporários foram removidos após os testes. A falta de display impede verificar visualmente janela/fullscreen e a plataforma Windows.

## Etapa 3 — Protótipo do jogador

**3.1 CONCLUÍDA** — Criada a cena reutilizável `scenes/player/player.tscn`, com raiz `CharacterBody3D`, formas provisórias nativas (corpo/cabeça/marcador frontal) e estrutura de câmera `CameraPivot → SpringArm3D → Camera3D`. Verificação estática da estrutura/nós e sub-recursos: PASS. A primeira execução do verificador estático falhou por uma expectativa incorreta no próprio teste (ele esperava `None` para o parent raiz; o parser recebe string vazia); ajustada a asserção e repetido com PASS. O carregamento real foi confirmado no scan e no teste 3.9/3.10 com Godot 4.7.2.

**3.2 CONCLUÍDA** — Adicionada cápsula de colisão ao jogador e um blockout à main scene com piso `StaticBody3D`, obstáculo e parede de limite, todos com formas primitivas correspondentes. Auditoria estrutural confirmou 3 colisores estáticos e o player instance: PASS. O teste 3.9 confirmou apoio no chão, parede bloqueante e câmera recolhendo no obstáculo.

**3.3 CONCLUÍDA** — `scripts/player/player_controller.gd` implementa movimento físico via `CharacterBody3D`, input vetorial, base horizontal do personagem/câmera, normalização diagonal, aceleração/desaceleração, gravidade e `move_and_slide()`. Auditoria estática: PASS; movimento em 4 direções, diagonal e física executadas e medidas no teste 3.9, PASS.

**3.4 CONCLUÍDA; visual não verificável** — Mouse horizontal gira o CharacterBody (movimento relativo à orientação); mouse vertical altera o pivot com limites -45°/+55°. O SpringArm tem volume esférico de colisão e exclui o RID do jogador para evitar auto-colisão. ESC usa a ação `pause` existente para alternar captura/liberação; clique esquerdo recaptura. A API/source do Godot e o teste runtime confirmaram que o SpringArm3D projeta na direção local +Z; a orientação padrão coloca a câmera atrás do personagem voltado para -Z, e a Camera3D olha na direção frontal. Pivot a y=1.75 e pitch inicial -5° posicionam a câmera ligeiramente acima do personagem. O teste confirma posição/altura/direção e retração do braço ao encontrar parede. No headless, Input.mouse_mode não é controlável como janela real; a captura foi encapsulada em estado lógico, com side effect do DisplayServer apenas fora do headless, permitindo testar handlers sem afirmar validação visual. Runtime: PASS.

**3.5 CONCLUÍDA** — `project.godot` adiciona apenas `sprint` em Shift físico; reutiliza `pause`/Escape existente para a captura, sem ação duplicada. Smoke test existente atualizado para exigir a ação sprint. Smoke test confirmou `sprint` vinculado; o teste 3.9 exercitou handlers mouse/ESC/clique: PASS.

**3.6 CONCLUÍDA** — Segurar Shift (`sprint`) seleciona 7.0 m/s em vez de 4.5 m/s; ambas usam a mesma aceleração, desaceleração, colisões e controle aéreo. Auditoria estática dos valores e do caminho de velocidade: PASS. O teste 3.9 mediu caminhada e corrida em movimento: ambas atingiram ≥90% da velocidade configurada, e corrida ficou >20% acima da normal. PASS.

**3.7 CONCLUÍDA** — Enum público `MovementState` expõe IDLE/WALKING/RUNNING/AIRBORNE, sinal `movement_state_changed` só em transições e getter nominal para uso futuro. Estado deriva de `is_on_floor()` e velocidade horizontal, não de animação ou estado artificial. O teste 3.9 verificou WALKING/RUNNING/IDLE/AIRBORNE e pelo menos três emissões reais do sinal. PASS.

**3.8 CONCLUÍDA; ajuste visual não avaliável** — Ajustes exportados uma única vez: caminhada 4.5 m/s, corrida 7.0 m/s, aceleração 18, desaceleração 22, gravidade 24, controle aéreo 0.35, snap 0.25, mouse 0.0022 rad/px, câmera 4.2 m, pitch inicial -5° e limites -45°/+55°. A velocidade horizontal usa `Vector3.move_toward`, mantendo o módulo de aceleração igual em diagonal e axial; o teste mede ambos após quatro passos. Auditoria estática dos valores e do tratamento isotrópico: PASS. A responsividade visual exata não pode ser afirmada sem display.

**3.9 CONCLUÍDA** — `tests/player_physics_test.gd` carrega/instancia a cena real e avança física real em floor/wall com colliders nativos. Godot 4.7.2: exit 0, `DEADLOCK_PLAYER_PHYSICS_RESULT {"ok":true}`. Verificou cápsula/câmera, câmera atrás e voltada à frente, SpringArm retraindo por obstáculo, deslocamento W/A/S/D, diagonal limitada e aceleração diagonal não maior, velocidades de caminhada/corrida, gravidade/aterrissagem, bloqueio pela parede, estados e sinal, mouse horizontal/pitch clamp e toggle/recaptura de captura via eventos injetados pelo `Viewport.push_input()` no pipeline `_input`. Isso testa o handler e a física no motor; não é teste visual nem usa mouse físico. Erros corrigidos: primeira execução tentou ler `global_position` antes de adicionar o player à árvore (ajustado para `position` antes de inserir); o eixo SpringArm foi confirmado na fonte do Godot como +Z, removendo rotação desnecessária; `Input.parse_input_event()` não encaminhou a motion como esperado no SceneTree de teste e a reutilização do objeto no mesmo frame emitiu warning, então usei eventos distintos e `Viewport.push_input()`. Headless não altera `Input.mouse_mode` real, então o jogador mantém estado lógico de captura e aplica `Input.mouse_mode` apenas em DisplayServer gráfico.

**3.10 CONCLUÍDA; validação headless PASS com ressalva do engine** — Scan do editor Godot exit 0; smoke test da Etapa 1 atualizado e error test da Etapa 2: exit 0; teste físico novo: exit 0; inicialização direta da main scene com Player: exit 0. Auditoria final verificou 11 referências `res://` (zero quebradas fora do fixture ausente intencional) e grafo de cenas `main → player` sem ciclos. Não há erros de parse/runtime do projeto. O scan gerou 10 ERROR do próprio engine por ter sido compilado `fontconfig=no` (sem headers/pkg-config disponíveis); é uma limitação do build headless e impede apenas suporte a fontes do sistema no editor, não afeta recursos ou scripts deste projeto.

### Arquivos da Etapa 3

**Criados:** `scenes/player/player.tscn` (cena reutilizável); `scripts/player/player_controller.gd`; `tests/player_physics_test.gd`; sidecars `scripts/player/player_controller.gd.uid` e `tests/player_physics_test.gd.uid` gerados pelo editor Godot.

**Alterados:** `scenes/main.tscn` (arena provisória com piso, obstáculo, parede e instância Player); `project.godot` (ação Shift `sprint`); `tests/project_smoke_test.gd` (ação nova e integração Player/arena); `docs/TECHNICAL_ARCHITECTURE.md`; este status. Nenhum asset externo, sistema futuro, arma, inimigo ou gameplay além do protótipo foi adicionado. GLB Inspector não foi alterado.

### Comandos e resultados da Etapa 3

| Verificação | Resultado |
|---|---|
| Godot usado | `4.7.2.stable.custom_build`, compilado de `4.7.2-stable` localmente para headless |
| Scan/importação do editor | `godot --headless --editor --path . --quit-after 600` → exit 0; 10 `ERROR` de fontconfig do engine custom; nenhum erro de parse, script, recurso ou caminho do projeto |
| Smoke test (Etapa 1 + main/player) | `godot --headless --path . --script res://tests/project_smoke_test.gd` → exit 0, `DEADLOCK_STAGE1_RESULT ok:true`, player entrou no SceneTree |
| Error test (Etapa 2) | `godot --headless --path . --script res://tests/project_error_test.gd` → exit 0, `DEADLOCK_ERROR_TEST_RESULT ok:true`; warning de override inválido intencional |
| Física/controles | `godot --headless --path . --script res://tests/player_physics_test.gd` → exit 0, `DEADLOCK_PLAYER_PHYSICS_RESULT {"ok":true}` |
| Inicialização direta | `godot --headless --path . --quit-after 2` → exit 0 |
| Referências/ciclos | 11 caminhos `res://` verificados; nenhum alvo real ausente (só fixture de erro intencional); `scenes/main.tscn → scenes/player/player.tscn`, zero ciclos |

**Limitações e avisos de build:** não há display/Wayland, portanto não foi possível abrir janela, inspecionar enquadramento/cores/oclusão visual, sentir responsividade real ou confirmar captura do mouse pelo sistema operacional. O teste `Viewport.push_input()` verifica o pipeline e os limites, mas não substitui mouse físico. A primeira tentativa de compilar o editor abortou porque `pkg-config` não existia. Para a build temporária, usei um probe compatível local apenas para SCons e desliguei integrações de sistema opcionais ausentes; não instalei nem adicionei dependências ao projeto. Sem headers de fontconfig e backend GUI, o scan do editor escreve 10 mensagens `ERROR` do próprio engine dizendo que suporte a fontes do sistema está desativado. O scan, execução e testes do jogo terminaram com exit 0, sem erros de parse/runtime do projeto; as formas/fontes do protótipo não dependem de fontes do sistema. A build source/engine SCons e os logs foram removidos após os testes. Não houve commit, push nem staging.

**Como executar e testar com uma instalação Godot 4:** abra o projeto ou execute `godot --path .` para iniciar a main scene, que monta a arena e o jogador. WASD movimenta, mouse olha, segurar Shift corre; Escape alterna captura/liberação do cursor e clique esquerdo recaptura. Rode os testes com `godot --headless --path . --script res://tests/project_smoke_test.gd`, `godot --headless --path . --script res://tests/project_error_test.gd` e `godot --headless --path . --script res://tests/player_physics_test.gd`.

## Build Windows obrigatório da Etapa 3

**SUCESSO — BUILD REAL E ARTIFACT VALIDADOS PELO GITHUB ACTIONS.**

- **Execução:** [Build Windows (Godot 4.7.2) #1](https://github.com/EtecStudy/DEADLOCK-OUTBREAK/actions/runs/40201595155) — conclusão `success`, evento `push`, em 2026-10-25.
- **Commit validado:** `348421d7059d5a06fd2906f742b5c72302d5e3f7` (`Run Godot commands with captured Windows output`).
- **Branch:** `arena/75e76c79-deadlock-outbreak`.
- **Runner:** `windows-latest`; todos os passos do job Windows x86_64 concluíram com sucesso.
- **Godot:** `4.7.2.stable.official.ed1daf0bf`.
- **Templates:** instalação do template oficial Godot 4.7.2 stable Windows x86_64 confirmada; `version.txt` correspondeu a `4.7.2.stable`.

### Testes e validação reais do run

| Verificação | Resultado do GitHub Actions |
|---|---|
| Import/scan headless do projeto | PASS — passo `Import project resources` concluído |
| `tests/project_smoke_test.gd` | PASS — exit code 0 |
| `tests/project_error_test.gd` | PASS — exit code 0 |
| `tests/player_physics_test.gd` | PASS — exit code 0 |
| Exportação `Windows Desktop` release | PASS |
| `build/windows/DeadlockOutbreak.exe` | Gerado e não vazio; **109.127.680 bytes** |
| `build/windows/DeadlockOutbreak.pck` | Gerado e não vazio; **25.072 bytes**; assinatura `GDPC` validada |
| Executável Windows | PE x86_64 validado; machine `0x8664` |
| Inicialização do jogo exportado | PASS — execução headless terminou sem erro de engine/script |
| ZIP `DeadlockOutbreak-Windows-x86_64.zip` | Criado, **39.205.123 bytes**; entradas EXE, PCK, `LEIA-ME.txt` e `SHA256SUMS.txt` verificadas |
| Upload do artifact | PASS — artifact `DeadlockOutbreak-Windows-x86_64`, **39.205.307 bytes**, não expirado no momento da consulta; expira em 2026-11-24 |

O artifact está listado na execução acima e disponível para download na seção **Artifacts** dessa página. O artifact é o ZIP final. A publicação foi concluída pela [execução de Actions #40207273936](https://github.com/EtecStudy/DEADLOCK-OUTBREAK/actions/runs/40207273936), no commit `ae59024e70f831b88d9ca84901520f1966354374`, e sua tag aponta para esse commit. A release pública [Deadlock Outbreak - Windows x86_64 (Godot 4.7.2)](https://github.com/EtecStudy/DEADLOCK-OUTBREAK/releases/tag/windows-x86_64-2026-10-25) contém `DeadlockOutbreak-Windows-x86_64.zip` (39.205.121 bytes). Pushes comuns não publicam releases automaticamente. Os EXE/PCK foram produzidos no runner Windows, não no workspace Linux local.

### Tentativas anteriores e ressalvas

As duas primeiras execuções (`40201216865` e `40201423906`) falharam no passo `Import project resources`. O endpoint de arquivo de logs do Actions não pôde ser acessado por este sandbox, então não foi possível confirmar a mensagem/causa interna dessas falhas e não atribuo uma causa como fato. Após as tentativas, o import/scan foi executado pelo editor headless com saída redirecionada para diagnósticos; a terceira execução, listada acima, passou em todos os passos. O run bem-sucedido inclui avisos não bloqueantes de depreciação do runtime Node 20 em `actions/checkout@v4` e `actions/upload-artifact@v4`.

O preset `Windows Desktop` em `export_presets.cfg` usa x86_64, PCK externo e inclui recursos do jogo; a opção de ícone fica vazia porque não há ícone próprio no projeto. O workflow independente `.github/workflows/build-windows.yml` fixa a distribuição oficial Godot 4.7.2 stable, roda testes antes da exportação, valida PE/PCK/startup, gera hashes e envia artifact por 30 dias. Um job separado publica uma GitHub Release somente quando o push contém o marcador deliberado `[publish-windows-release]`; pushes comuns continuam sem publicar release. O preset não exclui recursos de jogo; os filtros excluem documentação, testes e ferramentas/demonstrações do repositório.

### Credencial do workflow Supabase preexistente

Removi o valor embutido de `.github/workflows/fetch-supabase.yml` e substituí por `${{ secrets.SUPABASE_SERVICE_KEY }}`; também removi `set -x` para que argumentos expandidos não sejam ecoados no log. Para esse workflow funcionar, configure o repository Actions Secret `SUPABASE_SERVICE_KEY` em **Settings → Secrets and variables → Actions**. O valor anterior já esteve publicado no repositório/histórico; rotacione-o no Supabase. Esse workflow não foi executado nesta tarefa.

**Etapa 4 ainda não iniciada.**

## Versionamento contínuo por subtarefa

O workflow `.github/workflows/build-windows.yml` publica uma Release somente quando o commit da subtarefa aprovada contém um marcador de versão no formato `[release:v0.<etapa>.<subtarefa>]` (por exemplo, `[release:v0.3.10]`). A job de Release depende da conclusão de importação, testes, exportação, verificações PE/PCK, inicialização, ZIP e artifact; se algum passo falhar, a Release não é criada. A mesma execução define `application/file_version` e `application/product_version` do EXE como `0.<etapa>.<subtarefa>.0`. Tags existentes não são substituídas: uma colisão faz a publicação falhar em vez de sobrescrever uma versão anterior.

Para cada subtarefa futura: concluir implementação e testes, descrever o que foi feito no commit e incluir o marcador de tag correspondente; acompanhar o Actions até a Release/artifact serem confirmados; atualizar o histórico; então parar e aguardar autorização para a próxima subtarefa. Builds de pushes comuns continuam gerando apenas o artifact, sem criar uma Release.

As subtarefas concluídas antes desta política não receberam Releases individuais. A primeira versão retroativa corresponde ao último estado previamente validado, Etapa 3.10; não estou reconstruindo versões intermediárias de código que não foram exportadas e verificadas naquele momento.
