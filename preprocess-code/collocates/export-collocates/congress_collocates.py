from pathlib import Path

import sys
import os
import pickle

import re
import pandas as pd

import spacy
from spacy.symbols import nsubj, nsubjpass, dobj, pobj

nlp = spacy.load('en_core_web_sm', disable=['ner'])

class collocate_analysis:

    def import_data(fpath, sep, extraction_col, year_col, **kwargs): #col_name, **kwargs):
        sub = kwargs.get('sub', None)
    
        data = pd.read_csv(fpath, sep=sep)

        data = data[[extraction_col, year_col]]
        
        data[extraction_col] = data[extraction_col].str.lower()
    
        if sub is not None:
            data = preprocess_df.find_replace(data, extraction_col, sub)
   
        year = []
        text = []
        
        for index, row in data.iterrows():
            year.append(row[year_col])
            text.append(row[extraction_col])
        
        year_text_list = list(zip(year, text))
        
        year_text_dict = {}
    
        for (tup1, tup2) in year_text_list:
            if tup1 in year_text_dict:
                year_text_dict[tup1].append(tup2)
            else:
                year_text_dict[tup1] = [tup2]
            
        year_text_dict = {str(key): value for key, value in year_text_dict.items()}

        return year_text_dict
    
    
    def import_keywords(keywords):
        if keywords is not None:
            file_ext = ['.csv', '.tsv', '.xlsx', '.txt']
            
            if any(ext in keywords for ext in file_ext):
                with open(keywords, newline = '') as f:
                    keywords = [line.strip() for line in f]
                
            return keywords
    
    
    def make_regex(keywords_list):
        
        if keywords_list is not None:
            if type(keywords_list) != list:
                keywords_list = [keywords_list]
        
            regex = re.compile('|'.join(keywords_list))
        
        else:
            regex = False
        
        return regex
    
    
    def make_collocates_df(collocates, year, regex):
        
        collocates_df = pd.DataFrame(collocates, columns=['grammatical_collocates'])        
        
        if regex:
            filter = collocates_df['grammatical_collocates'].str.match(regex)                    
            collocates_df = collocates_df[filter]
                                        
        collocates_df['year'] = year
        
        return collocates_df
        
    
    def extract_nouns_and_modifiers(dic, **kwargs):
        
        keywords_list = kwargs.get('keywords_list', None)
        regex = collocate_analysis.make_regex(keywords_list)
        
        all_collocates_df = pd.DataFrame()
            
        for key, value in dic.items():
            year = key
        
            for sentence in value:
                doc = nlp(str(sentence))
            
                collocates = []
                for token in doc:
                    if token.dep == nsubj or nsubjpass or dobj or pobj:
                        for child in token.children:
                            if child.dep_ == 'amod':
                                collocates.append(str(child) + ' ' + str(token.text))
                                #collocates.append(str(token.text) + ' ' + str(child))
                        
                collocates_df = collocate_analysis.make_collocates_df(collocates, year, regex)
            
                all_collocates_df = pd.concat([all_collocates_df, collocates_df], axis=0)
        
        return all_collocates_df
    
    
    def extract_grammatical_collocates(dic, **kwargs):
        
        keywords_list = kwargs.get('keywords_list', None)
        regex = collocate_analysis.make_regex(keywords_list)
        
        all_collocates_df = pd.DataFrame()

        for key, value in dic.items():
            year = key
        
            for sentence in value:
                doc = nlp(str(sentence))
            
                collocates = []
                for token in doc:
                    if token.text != token.head.text:
                        #collocates.append(str(token.text) + ' ' + str(token.head.text))
                        collocates.append(str(token.head.text) + ' ' + str(token.text))
                
                    for child in token.children:
                        collocates.append(str(token.text) + ' ' + str(child))
                                                        
                collocates_df = collocate_analysis.make_collocates_df(collocates, year, regex)
            
                all_collocates_df = pd.concat([all_collocates_df, collocates_df], axis=0)
        
        return all_collocates_df
    
    
import re

def dict_keyword_lookup(dic, keywords_list):
    if keywords_list is not None:
        filtered_dic = {}
    
        regex = re.compile('|'.join(keywords_list))
    
        for key, value in dic.items():
            for item in value:
                if regex.search(item):
                    if key in filtered_dic:
                        filtered_dic[key].append(item)
                    else:
                        filtered_dic[key] = [item]
                        
        return filtered_dic
    
    else:
        return dic

import pandas as pd

from afinn import Afinn
from textblob import TextBlob
from nltk.sentiment.vader import SentimentIntensityAnalyzer
from nltk.corpus import sentiwordnet as swn
from nltk.sentiment.vader import SentimentIntensityAnalyzer

def afinn_sentiment(text):
    return Afinn().score(text)

def textblob_sentiment(text):
    return TextBlob(text).sentiment.polarity

def vader_sentiment(text):
    return SentimentIntensityAnalyzer().polarity_scores(text)

def sentiment_score_df(df, col_name):
    df['afinn'] = df[col_name].apply(afinn_sentiment)
    df['textblob'] = df[col_name].apply(textblob_sentiment)
    df['vader'] = df[col_name].apply(vader_sentiment)
    df['vader'] = df['vader'].apply(lambda score_dict: score_dict['compound'])    
    return df

def find_cum_sentiment_score_df(df, col_name):
    scored['combined_score'] = scored['afinn'] + scored['textblob'] + scored['vader']
    scored = scored[scored['combined_score'] != 0.000000]
    return df 

def main(input_file, extraction_col, year_col, **kwargs):
    keywords = kwargs.get('keywords', None)
    
    data = collocate_analysis.import_data(input_file, ',', extraction_col=extraction_col, year_col=year_col)#, sub='/users/sbuongiorno/preprocess_propertywords.csv')
        
    keywords = collocate_analysis.import_keywords(keywords)
    
    data = dict_keyword_lookup(data, keywords) # filter for setnences that contain 
    
    data = collocate_analysis.extract_nouns_and_modifiers(data, keywords_list=keywords)
    
    data = sentiment_score_df(data, 'grammatical_collocates')
    
    return data

#python name.py full_hansard_sample text year keywords

if __name__ == '__main__':
    debug = False
    
    if debug == True:
        input_file = '/users/sbuongiorno/hansard_samples/full_hansard_sample.csv'
        extraction_col = 'text'
        year_col = 'year'
        keywords = 'friend'
            
    else:
        try:
            input_file = sys.argv[1]
            job_id = sys.argv[2]
            extraction_col = 'sentence'
            year_col = 'year'
        except IndexError:
            exit('Missing input file argument')
            
        try:
            keywords = sys.argv[4]
        except:
            keywords = None
        
    data = main(input_file, extraction_col, year_col, keywords = keywords)
    
    if not data.empty:
        path = Path(input_file)
        
        export_fname = str(path).split('/')[-1]
        export_fname = os.path.splitext(export_fname)[0]
        export_fname = export_fname + '_' + str(job_id)

        #handle = open(str(path.parent) + '/' + export_fname + '.pickle', 'wb')
        
        handle = open('/users/sbuongiorno/' + export_fname + '.pickle', 'wb')

        pickle.dump(data, handle)
        print('Exported data as {}'.format(handle))

    else:
        exit()

