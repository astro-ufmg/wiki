---
title: Postando no blog da astro
author: [lsmenicucci]
date: 2025-12-15
categories:
  - meta
---

Todos queremos compartilhar o que sabemos, mas raramente temos a oportunidade de estarmos no mesmo ambiente, no mesmo instante e ou com a mesma disponibilidade. A solução para isto é o **blog da astro!**

<!-- more -->

O blog é feito utilizando o [mkdocs](https://www.mkdocs.org/) e o [Material for mkdocs](https://squidfunk.github.io/mkdocs-material/). Falando forma simples, estes programas convertem markdown em páginas da web, como esta! Tanto os arquivos markdown quanto as páginas geradas são hospedados em um [repositório da astro-ufmg](https://github.com/astro-ufmg/wiki). Para criar ou editar os posts, voce precisa clonar o repositório localmente:

```shell
$ git clone git@github.com:astro-ufmg/wiki.git
```

Ou usando https se voce preferir (a [autenticação por chaves com SSH](https://docs.github.com/pt/enterprise-cloud@latest/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key) é bem mais fácil). Mudanças no blog precisam ser submetidas primeiramente ao branch *draft*. Vamos então trocar localmente para este *branch*:

```shell
$ git checkout draft
Switched to branch 'draft'
Your branch is up to date with 'origin/draft'.
```

## Ajeitando o ambiente

Como dito antes, há scripts que convertem o conteúdo em markdown nestas páginas bonitas e arquivam os posts. Para facilitar o proceso, esta incluso no repositório um `Makefile` que facilita a instalação deste script. Para criar um *enviroment* com as dependencias necessárias, execute na raiz do repositório: 

```shell
$ make setup
```

Isto utilizará o pip (ou o `uv` se instalado) para criar um ambiente em `.venv` na raiz do repositório local com as dependencias necessárias. Para vizualizar o site localmente enquanto edita, use:

```shell
$ make serve 
```

**Toda vez** que algum conteúdo novo for publicado, lembre-se de executar:

```shell
$ make build 
```

## Criando um post

Listando os diretórios relevantes, vemos as seguinte estrutura:

```
├── content
│   ├── authors.yml
│   ├── images
│   │   └── authors
│   │       └── ...
│   └── posts
│       ├── ...
```

No `content/posts` voce pode criar um arquivo `.md` com o post que voce deseja criar. Suponhamos que o título do post seja "Baixando dados de aglomerados", o arquivo deve se chamar `baixando-dados-de-aglomerados.md` (evitando acentos e caracteres especiais) por uma questão de organização. Todo arquivo de post precisa de um cabeçalho, veja por exemplo o cabeçalho deste post que voce esta lendo:

```markdown
---
title: Postando no blog da astro
author: [lsmenicucci]
date: 2025-12-15
categories:
  - meta
---
```

O cabeçalho fica delimitado por `---`. Os nomes no campo `author` se referem a entradas no arquivo `content/authors.yml`, caso queira adicionar um autor, veja o arquivo, é autoexplicativo. Agora é so escrever depois do cabeçalho! Para que o post apresente uma versão resumida na lista de posts, coloque `<!-- more -->` quando voce quiser que o conteúdo abaixo fique restrito apenas a visualização única do post. Algo do tipo:

```markdown
Este parágrafo vai aparecer na lista de posts como um resumo!

<!-- more -->

Aqui eu já preciso clicar em "Ler mais" para continuar.
```

Editado o post, lembre-se de gerar o site novamente e *commitar* para o *branch draft*:

```shell
$ make build
$ git add content/posts/baixando-dados-de-aglomerados.md
$ git add docs 
$ git commit -m "Novo post: Baixando dados de aglomerados"
$ git push
```

Se voce não estiver editando um post simultaneamente a outra pessoa, o commit deve ser naturalmente aceito. Note que adicionamos o diretório `docs` onde as paginas da web foram geradas. É elas que estão sendo exibidas aqui! Agora 






