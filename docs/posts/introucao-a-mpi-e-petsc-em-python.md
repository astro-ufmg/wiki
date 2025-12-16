---
title: Introdução a MPI e PETSC em Python
author: [lsmenicucci]
date: 2025-12-15
categories:
  - python
  - mpi
---

Esta é uma breve introdução a utilização do MPI e o PETSC em programas escritos em Python. O material é escrito em forma de exemplos de complexidade incremental. Cada caso procura explorar da forma mais simples possivel como alguns aspectos fundamentais destas duas bibliotecas estão embutidos no código. Assume-se que o leitor tenha instalado os pacotes [mpi4py](https://mpi4py.readthedocs.io/en/stable/) e [petsc4py](https://petsc.org/release/petsc4py/). 
<!-- more -->

!!! Nota
    O `mpi4py` requer a instalação de alguma distribuição do MPI (OpenMPI, MPICH, ...). Se a instalação do `petsc4py` esta utilizando a versão do PETSc já presente no sistema, é preciso certificar que tal versão foi linkada a mesma versão do MPI que esta sendo utilizada pelo mpi4py. Caso contrário, erros estranhos referentes a má decodificação de mensagens do MPI podem ocorrer.

## Um *hello world*

Em sua forma mais simples, o MPI consiste em rodar várias réplicas do mesmo programa e executar chamadas em sua biblioteca quando quisermos que estes processos comuniquem. Neste caso simples (mas assustadoramente comum) cada instancia se diferencia por seu *rank*, um número inteiro maior ou igual a zero.

```python title="00-mpi-hello-world.py"
from mpi4py import MPI

rank = MPI.COMM_WORLD.Get_rank()
size = MPI.COMM_WORLD.Get_size()

print(f"Hello from {rank} out of {size}")
```
Rodando o programa com 2 mpi slots, resulta:
```shell
$ mpirun -n 2 python 00-mpi-hello-world.py
Hello from 1 out of 2
Hello from 0 out of 2
```

Neste caso nenhuma comunicação foi feita entre os programas. Eles só iniciaram, escreveram na tela e sairam.

!!! Nota 
    No MPI, é possivel ter grupos de processos que tomam acoes coletivas separadamente, como se cada grupo fosse uma sala de chat. O mais comum é ter um único grupo de processos que rodam réplicas de um mesmo programa, com caminhos de execucão bem parecios e realizam operacões entre si. O grupo ou *comunicador* primario é referenciado por `COMM_WORLD`. 

## Caminhos de execução diferentes

As vezes, queremos que processos diferentes realizem tarefas diferentes, como por exemplo, escrever um arquivo ou gerar um grafico serialmente. Tendo o *rank* atual em mãos, isto é fácil como escrever uma condicional:

```python title="01-mpi-branches.py"
from mpi4py import MPI
from time import sleep

rank = MPI.COMM_WORLD.Get_rank()

def work():
    sleep(1.0)
    print(f"Done working {rank}")

def work_more():
    sleep(2.0)
    print(f"Done working {rank}")

if rank != 0:
    work()
else:
    work_more()
```

```shell
$ mpirun -n 2 python 01-mpi-branches.py
Done working 1
Done working 0
```

Dependendo do rank da instancia que estamos, o programa pode tomar caminhos de execucão distintos. Para evitar *condicoes de corrida* na escrita ou exportacao de dados, é comum sincronizar os dados para uma unica instancia e realizar as operacoes somente dela.

## Básico de sincronização

A princípio, cada instância do MPI roda em paralelo (não é necessariamente assim) o que é um problema quando precisamos nos certificar que alguma parte do código seja executada por um único rank por vez. Neste caso, podemos utilizar uma primitiva de sincronização chamada *Mutex*:

```python title="02-mpi-mutex.py"
from mpi4py import MPI
from mpi4py.util import sync
from time import sleep

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

def print_list():
    for i in range(5):
        print(f"[rank {rank}] item {i}")
        sleep(0.1)
    print(f"[rank {rank}] done")

mutex = sync.Mutex(comm=comm)

print_list()

with mutex:
    print_list()
```

```
$ mpirun -n 2 python 02-mpi-mutex.py
[rank 1] item 0
[rank 0] item 0
[rank 0] item 1
[rank 1] item 1
[rank 0] item 2
[rank 1] item 2
[rank 1] item 3
[rank 0] item 3
[rank 0] item 4
[rank 1] item 4
[rank 1] done
[rank 0] done
[rank 1] item 0
[rank 1] item 1
[rank 1] item 2
[rank 1] item 3
[rank 1] item 4
[rank 1] done
[rank 0] item 0
[rank 0] item 1
[rank 0] item 2
[rank 0] item 3
[rank 0] item 4
[rank 0] done
``` 

Mutex (que significa *Mutual exclusive* e as vezes é chamado de *lock*) é uma forma de garantir que só uma instancia tenha acesso a algum recurso por vez. Note que na primeira chamada do `print_list()` as saidas intercalam entre os dois processos. Quando a funcao é chamada ao adiquirir o mutex, um processo espera o outro terminar.

Esta é a forma mais facil de evitar condicoes de corrida.

!!! Nota
    Usuários do MPI em linguagens de mais baixo nível, que interagem diretamente com a biblioteca do MPI vão perceber que não existe um objeto tal como o *Mutex*. A interface do `mpi4py` provém esta e algumas outras primitivas de sincronização construídas em cima das primitivas de troca de mensagem do MPI.

## Particionando vetores espacialment no PETSc

Movendo agora para um exemplo com o petsc4py, vejamos como particionar espacialmente uma grade em diferentes processos do MPI.  

```python title="03-petsc-global-local.py"
from mpi4py.util import sync
from petsc4py import PETSc

comm = PETSc.COMM_WORLD
rank = comm.getRank()

n = 10
dm = PETSc.DMDA().create([n], dof=1, stencil_width=1, comm=comm)

global_vec = dm.createGlobalVector() 
local_vec = dm.createLocalVector()

global_vec.set(rank)
global_vec.assemble()

dm.globalToLocal(global_vec, local_vec)

mutex = sync.Mutex(comm = comm.tompi4py())

with mutex:
    print(f"rank {rank}:")
    print("  global:", global_vec.getArray())
    print("  local :", local_vec.getArray())
 ```

`DMDA` é o nome dado a um objeto do PETSc que permite codificar informações de conectividade de uma grade estruturada (quadrilateral). Utilizamos este objeto posteriormente pra criar vetores e realizar comunicações coletivas facilitando a partição de um domnínio físico entre diferentes processos. 

 ```
$ mpirun -n 2 python 03-petsc-global-local.py
rank 1:
  global: [1. 1. 1. 1. 1.]
  local : [0. 1. 1. 1. 1. 1.]
rank 0:
  global: [0. 0. 0. 0. 0.]
  local : [0. 0. 0. 0. 0. 1.]
```

Na nomeclatura do PETSc, *global* é uma fatia (local) do vetor em questao, enquanto *local* é esta fatia com os *ghost points*. Note que:
1. Com `n = 10` em `-n 2` o `global_vec` tem 5 pontos enquanto o `local_vec` tem 6. Experimente mudar o valor de `stencil_width`.
2. `global_vec.set(rank)` enche o vetor com o valor do rank atual 
3. Ao chamar `dm.globalToLocal(global_vec, local_vec)` sincronizamos o valor dos ghost points entre os processos.

!!! Nota
    As interfaces `DM*` não são as mais primitivas no PETSc. Um vetor criado sem a utilização de algum variante deste objeto `DM` será trivialmente particionado entre os processos. Isto ocorre quando, por exemplo, queremos apenas resolver um problema de álgebra linear sem embutir qualquer informação sobre a conectividade dos nossos operadores.

## Exportando os vetores para uma única instância

Corriqueiramente, queremos utilizar o vetor (ou campo) completo em uma tarefa que não pode ser realizada em paralelo. Exemplos disto são polotagem dos resultados e exportação para um arquivo (é possível mas não trivial realizar escritas em paralelo). Neste caso, é comum reconstruir o vetor completo em um único processo, comumente o com rank zero (ele costumar se o mais lento). 

```python title="04-gather-on-zero.py"
from mpi4py.util import sync
from petsc4py import PETSc

comm = PETSc.COMM_WORLD
rank = comm.getRank()

n = 10
dm = PETSc.DMDA().create([n], dof=1, stencil_width=1, comm=comm)

global_vec = dm.createGlobalVector()
local_vec = dm.createLocalVector()

global_vec.set(rank)
global_vec.assemble()

dm.globalToLocal(global_vec, local_vec)

if rank == 0:
    vec_zero = PETSc.Vec().createSeq(global_vec.getSize(), comm=PETSc.COMM_SELF)
else:
    vec_zero = PETSc.Vec().createSeq(0, comm=PETSc.COMM_SELF)

scatter, _ = PETSc.Scatter().toZero(global_vec)
scatter.scatter(
    global_vec, vec_zero, PETSc.InsertMode.INSERT, PETSc.ScatterMode.FORWARD
)

print(f"[rank {rank}]: ", vec_zero.getArray())
```

Note que o `vec_zero` tem tipos diferentes em ranks diferentes. Isto evita critar uma copia do vetor global em cada rank. Sobre a comunicação, a função `PETSc.Scatter().toZero(...)` retorna uma tupla com dois contextos de scatter: global para local e local para local. Utilizamos o global para local.

```
$ mpirun -n 2 python 04-gather-on-zero.py
[rank 1]:  []
[rank 0]:  [0. 0. 0. 0. 0. 1. 1. 1. 1. 1.]
```

Note que o vetor `vec_zero` não ocupa memória no *rank* 1. Se quisessemos ser super eficientes sobre memoria, poderíamos receber, no *rank* zero, cada pedaço de um vetor sequencialmente, e realizar a operação desejada. Isto evitaria a situação em que o programa por completo teria dois campos inteiros alocatos em um único instante: $N$ pedaços distribuídos em $N$ *ranks* e um inteiro do *rank* zero.

Um comentário final sobre a diferença de nomeclatura entre as duas bibliotecas. No PETSc *scatter* são operações genericas que redistribuem dados entre os processos. Na nomeclatura tradicional, porém, *scatter* se refere ao caso em que enviamos uma informação da instancia local para as outras e *gather* é quando recebemos. As especificação do MPI também disponibiliza algumas operações que combinam as duas, chamadas de *reduce*. Um *reduce* pode somar todos os vetores distribuidos elemento a elemento ou tirar o máximo, por exemplo.

