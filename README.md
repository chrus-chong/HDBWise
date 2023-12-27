# HDBWise
![homepage](https://github.com/chrus-chong/HDBWise/assets/85006125/21dd5be5-122a-4b3b-ac8d-bd123de0577c)


HDBWise is a data-visualisation application that offers a suite of features designed to
streamline the property search process.

1. Comprehensive Data Access: It provides comprehensive and up-to-date (till 2023) data,
including price trends and information about nearby amenities.

2. Agent-Free Navigation: With HDBWise, users can navigate the property market and gain deeper insights into the housing market 
without the help of a real estate agent. It empowers buyers to take control of their
property search journey.

3. Interactive Visualisations: The application boasts interactive charts and
visualisations, enabling users to effortlessly compare different properties. This visual
richness enhances decision-making and property evaluation.
### How to use it
1. Download and unzip the repository
2. Open the ```app.R``` file in RStudio.
3. Run the app.

*Note 1: Transaction data is stored in the ```cleanedData.Rdata``` workspace file to ease of usage. To understand the data cleaning operations that were performed, refer to ```./data cleaning/cleanData.R```.*

*Note 2: There are hundreds of thousands of transactions. To ensure a smooth user experience, only transactions from 2016 onward are included by default. To perform data visualisation on all transactions from 1986 - 2023, delete ```Line 32``` from ```cleanData.R```.*

### HDBWise Functionalities
1. Nearby Amenities Discovery: By simply inputting a postal code, users can explore a
detailed map showcasing local amenities such as schools, shopping malls, and
more, giving a comprehensive view of the neighborhood.
![nearby](https://github.com/chrus-chong/HDBWise/assets/85006125/5a8d14cc-50d5-47f8-a27e-ad999c9ba2a6)


3. Price Appreciation Analysis: This function allows users to visualize property price
appreciation trends based on selected years, offering valuable insights into potential
investment returns.
![appreciation](https://github.com/chrus-chong/HDBWise/assets/85006125/e4df0ac9-f818-4577-aeb5-02683b4f5144)


5. Property Comparison Tool: Users can compare the features of two properties,
including amenities and other significant factors, by entering their respective postal
codes. This direct comparison aids in making more informed choices.
![comparison](https://github.com/chrus-chong/HDBWise/assets/85006125/fcb365c3-d4f6-454f-9294-bdadcc63e4ba)


7. Loan and Down Payment Calculator: Tailored to individual financial capabilities, this
tool recommends suitable properties based on the type of loan and available down
payment, simplifying financial planning in the property buying process.
![downpayment](https://github.com/chrus-chong/HDBWise/assets/85006125/94522b7b-81cf-4027-923b-0d4a9da5498f)


9. Neighborhood Search Functionality: A robust filter system that includes criteria such
as region, proximity to amenities, MRT station distance, storey range, and sale year
range, aids users in narrowing down their search to find the ideal property that meets
their specific needs.
![neighbourhood](https://github.com/chrus-chong/HDBWise/assets/85006125/d118f154-42b9-4d13-8499-0c6077a2e56a)


*Disclaimer: This was a group project and I only claim credit for the following*
- *Contributed to data cleaning*
- *Created functionality for Nearby Amenities Discovery*
- *Created functionality for Price Appreciation Analysis*
