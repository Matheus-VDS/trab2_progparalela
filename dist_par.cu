// Aluno: Matheus Vieira de Souza       RGA: 2021.1904.048-3
// Disciplina: Programação Paralela
// Distância de edição paralela
// Para compilar: nvcc dist_par.cu -o dist_par
// Para executar: ./dist_par <nome_arquivo_entrada.txt>
// OBS: Somente a solução inicial (com grid de um único bloco) está completa, 
// tentei fazer a solução completa mas contém erros.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

char *aloca_sequencia(int n)
{
	char *seq;

	seq = (char *)malloc((n + 1) * sizeof(char));
	if (seq == NULL)
	{
		printf("\nErro na alocação de estruturas\n");
		exit(1);
	}
	return seq;
}

int *aloca_matriz(int n)
{
	int *seq;

	seq = (int *)malloc((n) * sizeof(int));
	if (seq == NULL)
	{
		printf("\nErro na alocação de estruturas\n");
		exit(1);
	}
	return seq;
}

void libera(int n, char *s, char *r, int *d)
{
	free(s);
	free(r);
	free(d);
}

//----------------------------------------------
__global__ void distancia(int *d, int n, int m, int i, char *s, char *r)
{

	int posi, t, a, b, c, min;
	int cima, diag, atras;
	int linha, coluna;
	__syncthreads();

	if (i >= n)
	{
		posi = (i * (m + 1)) - ((i - n) * (m));
		posi = posi - threadIdx.x * (m);
	}
	else
		posi = i * (m + 1) - threadIdx.x * (m) + m + 2;

	atras = posi - 1;
	cima = posi - (m + 1);
	diag = posi - (m + 2);

	// Se é uma célula válida
	if ((d[posi] == 0 && posi > 0) && posi <= (n + 1) * (m + 1))
	{
		linha = (posi / (m + 1));
		coluna = posi - ((m + 1) * linha);

		t = (s[linha] != r[coluna] ? 1 : 0);
		a = d[atras] + 1;
		b = d[cima] + 1;
		c = d[diag] + t;

		// Calcula d[(i*(m+1)) + j] = min(a, b, c)
		if (a < b)
			min = a;
		else
			min = b;
		if (c < min)
			min = c;

		d[posi] = min;
	}
}

int main(int argc, char **argv)
{
	int n,	// Tamanho da sequência s
		m,	// Tamanho da sequência r
		*d, // Matriz de distâncias com tamanho (n+1)*(m+1)
		i, j;
	char *s,		  // Sequência s de entrada (vetor com tamanho n+1)
		*r;			  // Sequência r de entrada (vetor com tamanho m+1)
	FILE *arqEntrada; // Arquivo texto de entrada

	if (argc != 2)
	{
		printf("O programa foi executado com argumentos incorretos.\n");
		printf("Uso: ./dist_seq <nome arquivo entrada>\n");
		exit(1);
	}

	// Abre arquivo de entrada
	arqEntrada = fopen(argv[1], "rt");

	if (arqEntrada == NULL)
	{
		printf("\nArquivo texto de entrada não encontrado\n");
		exit(1);
	}

	// Lê tamanho das sequências s e r
	fscanf(arqEntrada, "%d %d", &n, &m);

	// Aloca vetores s e r
	s = aloca_sequencia(n);
	r = aloca_sequencia(m);
	// Aloca matriz d
	d = aloca_matriz((n + 1) * (m + 1));

	// Lê sequências do arquivo de entrada
	s[0] = ' ';
	r[0] = ' ';
	fscanf(arqEntrada, "%s", &(s[1]));
	fscanf(arqEntrada, "%s", &(r[1]));

	// Fecha arquivo de entrada
	fclose(arqEntrada);

	struct timeval h_ini; 
    struct timeval h_fim;
	gettimeofday(&h_ini, 0);

	// Inicializa matriz de distâncias d
	for (i = 0; i <= m; i++)
		d[i] = i;

	for (j = 1; j <= n; j++)
		d[(m * j) + j] = j;

	// Calcula distância de edição entre sequências s e r, por anti-diagonais
	int *d_M;
	char *d_s, *d_r;

	cudaMalloc((void **)&d_M, sizeof(int) * ((n + 1) * (m + 1)));
	cudaMalloc((void **)&d_s, sizeof(char) * (n + 1));
	cudaMalloc((void **)&d_r, sizeof(char) * (m + 1));

	cudaMemcpy(d_M, d, sizeof(int) * ((n + 1) * (m + 1)), cudaMemcpyHostToDevice);
	cudaMemcpy(d_s, s, sizeof(char) * (n + 1), cudaMemcpyHostToDevice);
	cudaMemcpy(d_r, r, sizeof(char) * (m + 1), cudaMemcpyHostToDevice);

	for (int i = 0; i < n + m + 1; i++)
		distancia<<<1, n>>>(d_M, n, m, i, d_s, d_r);

	cudaDeviceSynchronize();

	cudaMemcpy(d, d_M, sizeof(int) * ((n + 1) * (m + 1)), cudaMemcpyDeviceToHost);

	gettimeofday(&h_fim, 0);
	
    // Tempo de execução na CPU em milissegundos
	long segundos = h_fim.tv_sec - h_ini.tv_sec;
	long milisegundos = h_fim.tv_usec - h_ini.tv_usec;
	double tempo = (segundos * 1e3) + (milisegundos * 1e-3);

	printf("Distância = %d\n", d[((n + 1) * (m + 1)) - 1]);
	printf("Tempo CPU = %.2f ms\n", tempo);

	// Libera vetores s e r e matriz d
	libera(n, s, r, d);

	return 0;
}