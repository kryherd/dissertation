# Sloutsky Category Learning Task

## Design

**Experimental Conditions:**  

* **Supervised Learning:** Category-relevant dimensions are given to participants (e.g., all friendly aliens have big noses)
* **Unsupervised Learning:** Participants learn categories by viewing multiple instances of the category.
* **Sparse categories:** Cohere on a single dimension (others can vary)
* **Dense categories:** Cohere on multiple dimensions (dimensions are correlated)

The experiment is a 2 (supervised vs. unsupervised) x 2 (sparse vs. dense) within-subjects design. All participants complete all conditions.

## Stimuli

In this experiment, there are 4 different categories (aliens, bugs, flags, and flowers). Two of the categories (flowers and flags) are sparse, while two of the categories (aliens and bugs) are dense.

All categories have 7 dimensions. For dense categories, 6 of these dimensions are correlated. The seventh dimensions is allowed to vary randomly. For sparse categories, 6 of the dimensions vary randomly. The seventh dimension is category-relevant and defines the category.

All dimensions have two levels (e.g., for hair shape in aliens -- curly and straight). Within each level of the dimension, there are two values to allow for more variability.

### Statistical Density

Statistical density is the method that Sloutsky and colleagues use to define categories. Dense categories have multiple intercorrelated features, while sparse categories have few relevant features. There are a few equations to calculate statistical density. I'll place them below.

Statistical density can vary between 0 and 1. Higher values (closer to 1) are dense, while lower values (closer to 0) are sparse.  

![Entropy](./formulas/1.png)

H<sub>within</sub> is the entropy within the category.
H<sub>between</sub> is the entropy between the category and contrasting categories. To find total entropy, we sum entropy due to varying dimension and entropy due to varying relations among dimensions.

![Entropy2](./formulas/2.png)

This equation is the same whether you are calculating within-category entropy or between-category entropy. To find entropy due to dimensions, you use the following formulas:

![dimension-within](./formulas/3.png)  
![dimension-between](./formulas/4.png)

M is the total number of varying dimension.  
w<sub>i</sub> is the attentional weight of a particular dimension. For dimensions, we assume that this value is 1.0.  
p<sub>j</sub> is the probability of value *j* on dimension *i*.

Entropy due to relations uses the following formulas:

![relation-within](./formulas/5.png)  
![relation-between](./formulas/6.png)

O is the total number of possible dyadic relations among the varying dimensions.  
w<sub>k</sub> is the attentional weight of a relation. For relations, we use 0.5.  
p<sub>mn</sub> is the probability of the co-occurrence of values m and n on dimension k.

#### Calculating Statistical Density for my Stimuli
**Sparse Stimuli:**

M = 7  

For between-category entropy, all of the dimensions are the same. There is a 0.5 probability of each level of each dimensions being present. 

![sparse-dimbet-1](./formulas/7.png)  
![sparse-dimbet-2](./formulas/8.png)  
![sparse-dimbet-3](./formulas/9.png)  

For within-category entropy, the relevant dimension does not vary. So it does not contribute to the entropy. Its value goes to zero.

![sparse-dimwit-1](./formulas/10.png)  
![sparse-dimwit-2](./formulas/11.png)  
![sparse-dimwit-3](./formulas/12.png)

To calculate O (total number of possible dyadic relations among the dimensions), we use the following formula.

![totalrel](./formulas/13.png)

O = 21

Between categories (across the whole set), all dyadic relations have the same probability of co-occurrence (0.25). For each relation between dimensions, there are 4 possible combinations of the levels of those dimensions. They're all equally probable. Recall that for relations, we use an attentional weight of 0.5. So, we end up with the following.

![sparse-relbet-1](./formulas/15.png)  
![sparse-relbet-2](./formulas/14.png)  
![sparse-relbet-3](./formulas/16.png)

Within the target category, 15 of the dyadic relationships don't include the relevant feature. Thus, their probability of co-occurrence is .25. For 6 of the dyadic relations (any including the relevant feature), there is perfect co-occurrence: probability is either 0 or 1. This makes these terms go to zero.

![sparse-relwit-1](./formulas/17.png)
![sparse-relwit-2](./formulas/18.png)  
![sparse-relwit-3](./formulas/19.png)

Now comes the easy part -- adding up the entropies.

![sparse-within-total1](./formulas/20.png)  
![sparse-within-total2](./formulas/21.png)  
![sparse-between-total1](./formulas/22.png)  
![sparse-between-total2](./formulas/23.png)

And from that, we can calculate the density.

![sparse-density](./formulas/24.png)  
![sparse-density2](./formulas/25.png)


**Dense Stimuli:**

M = 7  

For between-category entropy, all of the dimensions are the same. There is a 0.5 probability of each level of each dimensions being present. 

![dense-dimbet-1](./formulas/7.png)  
![dense-dimbet-2](./formulas/8.png)  
![dense-dimbet-3](./formulas/9.png)  

For within-category entropy, six of the seven dimensions do not vary. So they do not contribute to the entropy. Their value goes to zero.

![dense-dimwit-1](./formulas/26.png)  
![dense-dimwit-2](./formulas/27.png)  
![dense-dimwit-3](./formulas/28.png)

O is the same as for the sparse categories.

![d-totalrel](./formulas/13.png)

O = 21

Between-category entropy for relations is the same as for sparse categories. Recall that for relations, we use an attentional weight of 0.5. So, we end up with the following.

![dense-relbet-1](./formulas/15.png)
![dense-relbet-2](./formulas/14.png)  
![dense-relbet-3](./formulas/16.png)

Within the target category, 6 of the dyadic relationships don't include the relevant feature. Thus, their probability of co-occurrence is .25. For 15 of the dyadic relations, there is perfect co-occurrence, so their values go to zero.

![dense-relwit-1](./formulas/29.png)
![dense-relwit-2](./formulas/30.png)    
![dense-relwit-3](./formulas/31.png)

Now comes the easy part -- adding up the entropies.

![dense-within-total1](./formulas/32.png)  
![dense-within-total2](./formulas/33.png)  
![dense-between-total1](./formulas/22.png)  
![dense-between-total2](./formulas/23.png)

And from that, we can calculate the density.

![dense-density](./formulas/34.png)  
![sparse-density2](./formulas/35.png)

To recap, the statistical density for my sparse stimuli is 0.25 and the density for my dense stimuli is 0.75.

## Procedure

#### Order Considerations

Previous research has shown that learning categories using an explicit, hypothesis-testing method can lead to this system being used even when it is not ideal (Ashby & Crossley, 2010). To check out the effects of order on this experiment in particular, I ran an order analysis. See the [order analysis](./OrderPilot/order_analysis.md) documentation for details.

This analysis, as well as prior studies, show that the optimal order to avoid transfer effects is as follows:

1. Unsupervised Sparse
2. Unsupervised Dense
3. Supervised Dense/Supervised Sparse

However, we will be running a much more extensive order analysis as Experiment 1 of the dissertation.