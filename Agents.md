# Agents.md — Guia para Criação e Edição do Mod BanditRelationship (B42)

Este documento serve como referência técnica para agentes de IA (como o GitHub Copilot) e desenvolvedores que desejam criar ou editar o mod **BanditRelationship** para o Project Zomboid Build 42.

---

## Referências Principais

| Recurso | Link |
|---|---|
| Guia de Criação de Mods para B42 (Steam) | https://steamcommunity.com/sharedfiles/filedetails/?id=3657551774 |
| Estrutura de Mod — PZ Wiki | https://pzwiki.net/wiki/Mod_structure |
| Lista de Itens — PZ Wiki | https://pzwiki.net/wiki/PZwiki:Item_list |
| Java Docs do Project Zomboid | https://demiurgequantified.github.io/ProjectZomboidJavaDocs/ |

---

## Visão Geral do Mod

**Nome:** Bandit Relationship [B42]  
**ID:** `BanditRelationship`  
**Autor:** Freeze  
**Versão PZ:** 42 (mínimo 42.0.0)  
**Dependência:** `Bandits2`  
**Workshop ID:** 3431259170  

O mod adiciona profundidade aos NPCs Bandidos (do mod Bandits), dando-lhes:
- Uma profissão pré-apocalipse aleatória
- Um humor diário mutável
- Sistema de relacionamento com o jogador (de -100 a +100)
- Diálogos temáticos (conhecer, amizade, dicas de sobrevivência, piadas)

---

## Estrutura de Pastas do Mod

```
Contents/
└── mods/
    └── BanditRelationship/
        ├── poster.png                      # Imagem de capa do mod
        └── 42/                             # Pasta específica do Build 42
            ├── mod.info                    # Metadados do mod
            ├── poster.png
            └── media/
                └── lua/
                    ├── client/             # Scripts executados apenas no cliente
                    │   ├── BanditDialogsAboutDay.lua
                    │   ├── BanditDialogue.lua
                    │   ├── BanditDialogueKeyPressed.lua
                    │   ├── BanditDialogueNewDay.lua
                    │   ├── BanditDialogueOptions.lua
                    │   └── BanditDialogueUI.lua
                    └── shared/             # Scripts compartilhados cliente-servidor
                        ├── BanditDialogueCompatibility.lua
                        ├── BanditRelationshipUpdate.lua
                        ├── BanditRelationships.lua
                        └── Translate/      # Traduções
                            ├── EN/IG_UI_EN.txt
                            ├── PTBR/IG_UI_PTBR.txt
                            ├── RU/IG_UI_RU.txt
                            └── UA/IG_UI_UA.txt
```

### Arquivo `mod.info`

```ini
name=Bandit Relationship [B42]
id=BanditRelationship
author=Freeze
description=...
poster=poster.png
pzversion=42
versionMin=42.0.0
require=\Bandits2
modversion=1
```

> **Nota:** A pasta `42/` indica compatibilidade exclusiva com o Build 42. Para suportar múltiplas versões, crie pastas separadas (ex: `41/`, `42/`).

---

## Estrutura de Mod (B42) — Resumo do PZ Wiki

A estrutura recomendada pelo PZ Wiki para mods no Build 42 é:

```
mods/
└── SeuMod/
    └── 42/
        ├── mod.info
        └── media/
            ├── lua/
            │   ├── client/      # Lógica de UI e interação do jogador
            │   ├── server/      # Lógica exclusiva do servidor
            │   └── shared/      # Lógica compartilhada (cliente + servidor)
            ├── scripts/         # Definições de itens, receitas, veículos
            ├── maps/            # Mapas customizados
            ├── textures/        # Texturas e imagens
            └── sound/           # Arquivos de áudio
```

**Regras importantes:**
- Arquivos em `client/` são carregados apenas no cliente
- Arquivos em `server/` são carregados apenas no servidor
- Arquivos em `shared/` são carregados em ambos
- O `mod.info` é obrigatório e define o ID único do mod

---

## Arquitetura do Código

### `BanditRelationships.lua` (shared)

Módulo central de dados. Gerencia o sistema de relacionamentos:

```lua
BanditRelationships = BanditRelationships or {}

-- Estrutura de dados de um relacionamento:
-- {
--   knows            = false,       -- Se o jogador conhece o bandido
--   relation         = 0,           -- Pontuação -100 a +100
--   banditId         = bandit.id,
--   name             = bandit.fullname,
--   profession       = string,      -- Profissão pré-apocalipse
--   maritalStatus    = string,      -- Estado civil
--   numberOfChildren = int,
--   hasChildren      = bool,
--   personalitie     = string,      -- Personalidade (note: campo com typo no código original)
--   dayMood          = string,      -- Humor do dia
-- }
```

**Funções-chave:**

| Função | Descrição |
|---|---|
| `BanditRelationships.initModData()` | Inicializa a estrutura de dados no `ModData` do jogador |
| `BanditRelationships.getRelationship(player, bandit)` | Retorna (ou cria) o relacionamento com um bandido |
| `BanditRelationships.modifyRelationship(player, bandit, amount)` | Modifica a pontuação de relacionamento (clamped -100 a 100) |
| `BanditRelationships.knowBandit(player, bandit)` | Marca o bandido como conhecido e inicializa relação em 5 |
| `BanditRelationships.removeBandit(bandit)` | Remove um bandido da tabela de dados |
| `BanditRelationships.createRelationship(bandit)` | Cria um novo registro de relacionamento com atributos aleatórios |
| `BanditRelationships.getRandomProfession()` | Retorna uma profissão aleatória da lista |
| `BanditRelationships.getRandomDayMood()` | Retorna um humor do dia aleatório |
| `BanditRelationships.getRandomMaritalStatus()` | Retorna estado civil aleatório |
| `BanditRelationships.getRandomPersonality()` | Retorna personalidade aleatória |

**Armazenamento de dados:**  
O mod usa `getSpecificPlayer(0):getModData()` para persistir os dados em `worldData.BanditRelationships` (tabela indexada pelo ID do bandido).

---

### `BanditDialogue.lua` (client)

Define o sistema de diálogos e categorias:

```lua
-- Adicionar um diálogo a uma categoria:
BanditDialogues.addDialogue(
    topic,          -- "friendly", "know-one", "know-two", etc.
    playerLine,     -- getText("IGUI_BanditDialog_Question_X")
    banditLine,     -- getText("IGUI_BanditDialog_Answer_X")
    earnBoreMin,    -- Mínimo de tédio a modificar
    earnBoreMax,    -- Máximo de tédio a modificar
    earnRelationMin, -- Mínimo de relação a modificar
    earnRelationMax  -- Máximo de relação a modificar
)

-- Adicionar uma categoria de diálogo:
BanditDialogues.addCategory(
    insideCategory, -- Categoria pai (ex: "friendly-one")
    uniqueId,       -- ID único da categoria (ex: "friendly")
    name,           -- Nome exibido
    minRelation     -- Relação mínima para exibir esta categoria
)
```

**Tópicos de diálogo disponíveis:**
- `"friendly"` — Saudações e conversa amigável
- `"know-one"` — Primeiras perguntas de conhecimento
- `"know-two"` — Perguntas mais profundas
- `"jokes"` — Piadas e humor
- `"survive-tips"` — Dicas de sobrevivência
- `"about-day"` — Perguntas sobre o dia atual

---

### `BanditDialogueUI.lua` (client)

Interface gráfica do sistema de diálogos. Renderiza a lista de bandidos e os menus de conversa usando a API Lua de UI do PZ.

**Funções relevantes:**
- `BanditDialogueUI.getSortedBanditsByDistance()` — Ordena bandidos por proximidade ao jogador
- `onMouseDownOnGameWorld(x, y)` — Gerencia clique no mundo para movimentação de bandidos

---

### `BanditDialogueNewDay.lua` (client)

Atualiza o humor diário (`dayMood`) de cada bandido quando um novo dia começa.

---

### Traduções

Arquivos de tradução ficam em `media/lua/shared/Translate/<LANG>/IG_UI_<LANG>.txt`.

**Formato:**
```lua
IG_UI_EN = {
    IGUI_BanditDialog_SpeakWith = "Speak with",
    IGUI_BanditDialog_Category_Friendly = "Friendly",
    -- ...
}
```

**Idiomas suportados:** EN, PTBR, RU, UA

Para adicionar um novo idioma, crie a pasta e o arquivo seguindo o padrão acima.

---

## Java Docs — APIs Relevantes

A documentação Java do PZ está em: https://demiurgequantified.github.io/ProjectZomboidJavaDocs/

Pacotes mais relevantes para este mod:

| Pacote | Uso |
|---|---|
| `zombie.characters` | Acesso a dados de personagens/NPCs |
| `zombie.characters.Moodles` | Sistema de estados do personagem |
| `zombie.characters.professions` | Profissões do jogo base |
| `zombie.characters.skills` | Sistema de habilidades |
| `zombie.inventory` | Sistema de inventário |
| `zombie.iso` | Posicionamento no mundo |
| `zombie.core.logger` | Sistema de logging |

**Funções Lua expostas pela Java API (mais usadas neste mod):**

```lua
getSpecificPlayer(0)          -- Retorna o jogador principal
getPlayer()                   -- Retorna o jogador ativo
player:getModData()           -- Retorna tabela de dados persistentes do mod
ZombRand(min, max)            -- Número aleatório entre min e max-1
getText("IGUI_Key")           -- Retorna string traduzida
Events.OnGameStart.Add(fn)    -- Hook para início do jogo
Events.OnMouseDown.Add(fn)    -- Hook para clique do mouse
```

---

## Lista de Itens do PZ

Referência: https://pzwiki.net/wiki/PZwiki:Item_list

Este mod não adiciona itens ao jogo, mas caso seja necessário adicionar itens no futuro, o padrão é criar arquivos `.txt` em `media/scripts/`:

```
module Base {
    item MeuItem
    {
        DisplayName  = Nome do Item,
        Type         = Normal,
        Weight       = 0.1,
        Icon         = MeuItem,
        -- ...
    }
}
```

Consulte o PZ Wiki para a lista completa de propriedades de itens e os IDs dos itens existentes no jogo.

---

## Guia Rápido: Como Adicionar um Novo Diálogo

1. **Adicione as strings de tradução** em cada arquivo de idioma em `Translate/`:
   ```lua
   -- Chaves em inglês descritivo, valores traduzidos para cada idioma
   IGUI_BanditDialog_Question_MinhaNovaQuestao = "Your new question here?",
   IGUI_BanditDialog_Answer_MinhaNovaResposta  = "Bandit's response here.",
   ```

2. **Registre o diálogo** no arquivo `BanditDialogue.lua`, dentro da função de inicialização:
   ```lua
   BanditDialogues.addDialogue(
       "know-one",
       getText("IGUI_BanditDialog_Question_MinhaNovaQuestao"),
       getText("IGUI_BanditDialog_Answer_MinhaNovaResposta"),
       1, 3,    -- boreMin, boreMax
       0, 2     -- relationMin, relationMax
   )
   ```

3. **Teste no jogo** usando o mod ativo com o Bandits2.

---

## Guia Rápido: Como Adicionar um Novo Atributo ao Bandido

1. **Adicione a geração aleatória** em `BanditRelationships.lua`:
   ```lua
   function BanditRelationships.getRandomNovoAtributo()
       local valores = { "Valor1", "Valor2", "Valor3" }
       return valores[ZombRand(#valores) + 1]
   end
   ```

2. **Inclua na função `createRelationship`**:
   ```lua
   data[id] = {
       -- ... atributos existentes ...
       novoAtributo = BanditRelationships.getRandomNovoAtributo(),
   }
   ```

3. **Use o atributo nos diálogos** dentro de `BanditDialogue.lua` ou `BanditDialogueUI.lua`:
   ```lua
   local rel = BanditRelationships.getRelationship(player, bandit)
   local valor = rel.novoAtributo
   ```

---

## Ferramentas Recomendadas

| Ferramenta | Uso |
|---|---|
| **Visual Studio Code** | Editor principal (com extensão *Umbrella* para highlight Lua da API PZ) |
| **IntelliJ IDEA** | Navegação nos arquivos Java descompilados do jogo |
| **GIMP / Photoshop / Krita** | Edição de imagens (posters, ícones) |
| **Blender** | Modelagem 3D (se necessário) |

### Extensões VSCode para PZ Modding

- `Umbrella` — Syntax highlight para a API Lua do PZ
- `Project Zomboid Script Support` — Syntax highlight para Scripts
- `Zed Script` — Syntax highlight alternativo para Scripts

---

## Boas Práticas de Modding para B42

1. **Comece pequeno:** Implemente uma feature de cada vez e teste imediatamente.
2. **Use os recursos disponíveis:** Leia o PZ Wiki, Java Docs e os guias da comunidade.
3. **Estude mods existentes:** Analise mods com funcionalidades similares para entender os padrões.
4. **Evite AI cega:** Ferramentas de IA podem gerar código incorreto para a API do PZ — sempre valide o código gerado contra os Java Docs e o Wiki.
5. **Prefira `shared/`:** Coloque lógica que não depende de UI em `shared/` para compatibilidade com modo multiplayer.
6. **Nomeie funções com prefixo do mod:** Ex: `BanditRelationships.minhaFuncao()` — evita conflitos com outros mods.
7. **Use `ModData`:** Persista dados usando `player:getModData()` — é a forma oficial e segura de salvar dados de mods.
8. **Teste com o Bandits2:** Este mod depende do mod Bandits2 — sempre teste com ele ativo.

---

## Compatibilidade e Dependências

- **Dependência obrigatória:** Bandits2 (`require=\Bandits2` no `mod.info`)
- O arquivo `BanditDialogueCompatibility.lua` gerencia a integração com o mod Bandits2
- Sempre verifique as APIs expostas pelo Bandits2 antes de chamar funções de NPCs

---

## Referências Adicionais da Comunidade

- [PZ Wiki — Modding](https://pzwiki.net/wiki/Modding)
- [PZ Wiki — Game Files](https://pzwiki.net/wiki/Game_files)
- [PZ Wiki — Mapping](https://pzwiki.net/wiki/Mapping)
- [PZ Wiki — JavaDocs](https://pzwiki.net/wiki/JavaDocs)
- [Comunidades de Modding PZ](https://pzwiki.net/wiki/Modding#Communities)
