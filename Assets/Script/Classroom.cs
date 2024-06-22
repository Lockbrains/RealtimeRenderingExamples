using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Classroom : MonoBehaviour
{
    // Start is called before the first frame update
    public float speed;
    public float sinking_speed;
    public float sinking_start_time;
    public bool isMoving;

    [Header("Background Information")]
    public GameObject songInfoPanel;
    public Text title;
    public Text author;
    public string songTitle;
    public string songAuthor;

    private float passedTime;
    private bool start_to_sink;

    void Start()
    {
        passedTime = 0;
    }

    // Update is called once per frame
    void Update()
    {
        // Only move when game start
        if(GameManager.S.status == GameManager.GameStatus.GameStart)
        {
            if (isMoving)
            {
                Vector3 curPos = this.transform.position;
                curPos.x += Time.deltaTime * speed;
                if(!start_to_sink)
                {
                    curPos.y = 0.5f * Mathf.Cos(passedTime * 0.8f) + 0.45f;
                } else
                {
                    // start to sink
                    curPos.y -= Time.deltaTime * sinking_speed;
                }
                passedTime += Time.deltaTime;
                this.transform.position = curPos;
            }

        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.transform.tag == "Player")
        {
            isMoving = false;
            StartCoroutine(ShowInfo());
        }

        if(other.transform.tag == "Sink")
        {
            start_to_sink = true;
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.transform.tag == "Player")
        {
            isMoving = true;
        }
    }

    IEnumerator ShowInfo()
    {
        title.text = songTitle;
        author.text = songAuthor;
        songInfoPanel.SetActive(true);
        yield return new WaitForSeconds(7.0f);
        songInfoPanel.SetActive(false);
    }
}
