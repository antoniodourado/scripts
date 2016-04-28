#!/bin/bash
clear

#Verifica se foi passado algum percentual de divisão entre train e test.
#O percentual se refere ao train. O restante é de test.
#Caso nada seja informado, o valor de 50% é assumido
if [[ $# -eq 0 ]]; then
	echo "Nenhum percentual de treinamento informado. Assumindo 50%."
	PERC_TRAIN=0.5
elif [[ $(echo "$1 > 1" | bc) -eq 1 ]]; then
	echo 'Percentual de treinamento deve ser no intervalo [0,1].'
	exit 1
else
	PERC_TRAIN=$1
fi

#Remove os diretórios de train e test anteriores
rm -rf "train"
rm -rf "test"

PERC_TRAIN_FULL=$(echo "$PERC_TRAIN * 100" | bc | xargs printf "%.0f")

#Verifica os diretórios de imagens presentes para a divisão
#TARGET_DIRS=`ls -l . | egrep '^d' | awk '{print $9}'`
OLFIFS=$IFS
IFS=$'\n'
TARGET_DIRS=`ls -d */ | sed 's/\//\\n/g'`


#exit 1
TOTAL_FILES=$(find $TARGET_DIRS -type f -printf x | wc -c)
TOTAL_TRAIN=$(echo "$TOTAL_FILES * $PERC_TRAIN" | bc | xargs printf "%.0f")
TOTAL_TEST=$(echo $TOTAL_FILES-$TOTAL_TRAIN | bc)

echo 'Diretórios alvo: ' $TARGET_DIRS
echo 'Total de arquivos: ' $TOTAL_FILES
echo 'Percentual de imagens de treino: ' $PERC_TRAIN_FULL'%'
echo 'Total de Imagens de Treino: ' $TOTAL_TRAIN
echo 'Total de Imagens de Teste: ' $TOTAL_TEST

#cria subdiretórios train e test
mkdir "train"
mkdir "test"

touch "train/train.txt"
touch "test/test.txt"

rm -rf labels.txt

#Cria subdiretórios de cada base em train e test
#Cria labels baseadas nos diretórios
for dir in $TARGET_DIRS; do
	echo 'Criando diretórios train/test para '$dir
	mkdir 'train/'$dir
	mkdir 'test/'$dir
	echo "$dir" >> labels.txt
done

#Copia as labels para train e test
cp labels.txt "train/"
cp labels.txt "test/"

for dir in $TARGET_DIRS; do

	DIRFILES=`ls $dir | sort -R`

	TOTAL_FILES=$(find $dir -type f -printf x | wc -c)
	TOTAL_TRAIN=$(echo "$TOTAL_FILES * $PERC_TRAIN" | bc | xargs printf "%.0f")
	
	echo 'Copiando '$TOTAL_TRAIN' imagens de treino de '$dir

	if [[ $TOTAL_TRAIN -gt 0 ]]; then		

		TRAINFILES=`echo "${DIRFILES}" | head -$TOTAL_TRAIN`
		for trains in $TRAINFILES; do
			`cp $dir/$trains train/$dir`
			FPATH=`readlink -f train/$dir/$trains`
			FLABEL=$(echo `grep -n $dir train/labels.txt | cut -d : -f1` - 1 | bc)
			`echo $FPATH' '$FLABEL >> train/train.txt`
		done
		shuf train/train.txt > train/temp.txt
		mv train/temp.txt train/train.txt
	fi

	TOTAL_TEST=$(echo $TOTAL_FILES-$TOTAL_TRAIN | bc)
	echo 'Copiando '$TOTAL_TEST' imagens de teste de '$dir

	if [[ $TOTAL_TEST -gt 0 ]]; then
		TESTFILES=`echo "${DIRFILES}" | tail -$TOTAL_TEST`
		for tests in $TESTFILES; do
			`cp $dir/$tests test/$dir`
			FPATH=`readlink -f test/$dir/$tests`
			FLABEL=$(echo `grep -n $dir test/labels.txt | cut -d : -f1` - 1 | bc)
			`echo $FPATH' '$FLABEL >> test/test.txt`
		done
		shuf test/test.txt > test/temp.txt
		mv test/temp.txt test/test.txt
	fi

done
IFS=$OLDIFS