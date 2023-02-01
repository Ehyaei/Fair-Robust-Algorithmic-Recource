############################################################
#                                                          #
#               Extract New ASCIncome Data                 #
#                                                          #
############################################################

import pandas as pd
import numpy as np
from folktables import ACSDataSource, ACSIncome


data_source = ACSDataSource(survey_year='2018', horizon='1-Year', survey='person')
ca_data = data_source.get_data(states=["CA"], download=True)
income, labels, _ = ACSIncome.df_to_pandas(ca_data)
income['label'] = labels
income.to_csv('data/ASCIncome.csv', index=False)
