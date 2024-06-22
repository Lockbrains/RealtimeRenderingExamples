using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScreenShatterExplosion : MonoBehaviour
{
    public Transform explosionTransform;
    public GameObject lightboard;

    public float explosionForce;
    // Start is called before the first frame update
    void Start()
    {
        foreach (Transform child in transform)
        {
            child.gameObject.SetActive(false);
            if (child.TryGetComponent<Rigidbody>(out Rigidbody childRigidbody))
            {
                // childRigidbody.AddExplosionForce(explosionForce, explosionTransform.position, 10f); 
                childRigidbody.useGravity = false;
                childRigidbody.isKinematic = true;
            }
        }
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            StartCoroutine(StartAnim());
        }
    }

    IEnumerator StartAnim()
    {
        foreach (Transform child in transform)
        {
            child.gameObject.SetActive(true);
            if (child.TryGetComponent<Rigidbody>(out Rigidbody childRigidbody))
            {
               // childRigidbody.AddExplosionForce(explosionForce, explosionTransform.position, 10f); 
               childRigidbody.useGravity = false;
               childRigidbody.isKinematic = true;
            }
        }

        //yield return new WaitForSeconds(1.0f);
        float remainingTime = 1.0f;
        float frames = 1.0f / Time.deltaTime;
        float powerDelta = 4.0f / frames;
        float biasDelta = (1.0f - 0.985f) / frames ;
        float currentPower = 10.0f;
        float currentBias = 1.0f;
        while (remainingTime > 0f)
        {
            foreach (Transform child in transform)
            {
                if (child.TryGetComponent<MeshRenderer>(out MeshRenderer mr))
                {
                    mr.materials[0].SetFloat("_FresnelPower", currentPower);
                    mr.materials[0].SetFloat("_FresnelBias", currentBias);
                }
            }

            currentPower -= powerDelta;
            currentBias -= biasDelta;

            remainingTime -= Time.deltaTime;
            yield return new WaitForSeconds(Time.deltaTime);
        }
        
        
        foreach (Transform child in transform)
        {
            child.gameObject.SetActive(true);
            if (child.TryGetComponent<Rigidbody>(out Rigidbody childRigidbody))
            {
                childRigidbody.useGravity = true;
                childRigidbody.isKinematic = false;
                childRigidbody.AddExplosionForce(explosionForce, explosionTransform.position, 10f); 
            }
        }
        lightboard.SetActive(false);
    }
}
