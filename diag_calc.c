// Para compilar: gcc diag_calc -o diag_calc
// Para executar: ./diag_calc
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/* __global__ void imprime(int *d_vetor, int *max_d){
    
     int tid_global = blockIdx.x * blockDim.x + threadIdx.x;
     printf("\nComeço do DEVICE 1...\n");
    
     __syncthreads();

     if (tid_global <= *max_d){
         d_vetor[tid_global] += 0;
         printf("Na GPU:  %d \n", tid_global);
         if (tid_global % 4 == 0)
             printf("\n%d seu bloco: %d\n",d_vetor[tid_global], blockIdx.x);
         else
             printf("%d seu bloco: %d\n",d_vetor[tid_global], blockIdx.x);
     }
    
}
*/
int *alocaVetor(int *Matriz, int n, int m){
    Matriz = (int *) malloc(sizeof(int) * n*m);
    if(Matriz == NULL){
        perror("Nao alocou vetor\n"); 
        exit(1);
    }
    
    for (int i = 0; i < n*m; i++)
        Matriz[i] = i;
    return Matriz;
}


//Para cada diagonal retornar um vetor com os pontos da diagonal
int *pegaDi(int *M, int n, int m, int ini){
    printf("valor de i: %d", ini);
    int *vec;
    int aux;
    int i, 
        cont =0; // contador de celulas da diagonal

    ini = ini*m;
    printf(" valor do vetor %d", ini);

    vec = (int *) malloc( sizeof(int) * (m-1) );

    if (vec != NULL){
        for (int i=0; i< n;i++){
            vec[i] = -1;
        //printf(" %d", M[i]);
        }
    }


    printf("\n");
    if (vec != NULL)
    {
        for(int i= ini; (i > 0  && cont < n) && M[i] !=-1; i -= m-1){
            if (i <= n*m-1){
                vec[cont] = M[i];
                M[i] = -1;
                cont++;
            }
        }
    }
    return vec;
}

// Matriz NxM (3x5)
int main(int argc, char *argv[]){

    printf("Começo do HOST...\n");
    int *Matriz;
    int n, m;
    int *max, *max_d;
    
    int *h_vetor;
    int *d_vetor;

    printf("Digite os numeros de n e m\n");
    scanf("%d %d", &n, &m);

    Matriz = alocaVetor(Matriz, n, m);


    max     = (int *) malloc(sizeof(int));
    max_d   = (int *) malloc(sizeof(int));
    h_vetor = (int *) malloc(sizeof(int) * n*m);
    //d_vetor =(int *) malloc(sizeof(int) * n*m);

    *max = (n*m);

    printf("Valor do max %d\n", *max);

    for(int i=0; i<n*m; i++){
        h_vetor[i] = i;
    }

    /*cudaMalloc( (void **)&h_vetor, sizeof(int) * 5);
    cudaMalloc( (void **)&d_vetor, sizeof(int) * n*m);
    cudaMalloc( (void **)&max_d  , sizeof(int));


    cudaMemcpy(d_vetor, h_vetor, sizeof(int) * n*m , cudaMemcpyHostToDevice);
    cudaMemcpy(d_vetor, Matriz, sizeof(int) * n*m , cudaMemcpyHostToDevice);
    cudaMemcpy(max_d,   max,    sizeof(int),       cudaMemcpyHostToDevice);

   
    CHAMADA DO KERNEL
    Para cada diagonal ja separada mandar para a GPU(mandar sempre 2, pois a primeira diagonal que mandar vai escrever na segunda)
    
     for (int i=2; i< -1+n+m-4; i++)
        imprime<<<n, m>>>( d_vetor, max_d); 


    printf("\n");
    cudaDeviceSynchronize();
    
    cudaMemcpy( h_vetor, d_vetor, sizeof(int) *n*m ,cudaMemcpyDeviceToHost);*/

    // matriz para armazenar as diagonais
    int **vec;
    vec = (int **) malloc(sizeof(int *) * (n+m-3));

    if(vec == NULL)
        perror("nao alocou a matriz de diagonais\n");

    for(int i=0; i < m; i++)
        vec[i] = (int *) malloc( sizeof(int) *m-1);

    
    // Laço para pegar todas as diagonais que seram usadas no calculo
    
    for (int i= 2; i < n+m-1; i++){
        vec[i-2] = pegaDi(h_vetor, n, m, i);
        printf("passou aqui %d \n", i-2);
    }

    // Impressao do vetor das diagonais
    printf("Diagonais");
    for(int i=0; i<n+m-3; i++){  
        for (int j=0; j<n; j++){    
            //vec[i][j] = i*m +j;
            printf("%3d ", vec[i][j]);
        }
        printf("\n");
    }

    // Imprime o valor da celula e a posicao  i e j
    printf("Matriz Bidimensional\n");
    for(int i=0; i<n; i++){
        for (int j=0; j<m; j++)
            printf("%5d/(%d,%d) ", h_vetor[m*i+j], i, j);
        printf("\n");
    }

    /* for (int i=0; i < n*m; i++)
         printf("%d\n", h_vetor[i]);

    cudaFree(d_vetor);*/

    printf("HOST terminado!\n");
    return 0;   
}